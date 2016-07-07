-module(flare_topic).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-ignore_xref([{flare_topic_utils, server_name, 2}]).

-export([
    init/0,
    produce/2,
    start/1,
    start/2,
    stop/1
]).

%% public
-spec init() ->
    ok.

init() ->
    ets:new(?ETS_TABLE_TOPIC, [
        named_table,
        public,
        {write_concurrency, true}
    ]),
    ok.

-spec produce(topic_name(), msg()) ->
    ok | {error, atom()}.

produce(Topic, Message) ->
    case flare_utils:ets_lookup_element(?ETS_TABLE_TOPIC, Topic) of
        undefined ->
            {error, topic_not_started};
        PoolSize ->
            N = shackle_utils:random(PoolSize) + 1,
            topic_buffer_msg(Topic, N, {produce, Message}),
            ok
        end.

-spec start(topic_name()) ->
    ok | {error, atom()}.

start(Topic) ->
    start(Topic, []).

-spec start(topic_name(), topic_opts()) ->
    ok | {error, atom()}.

start(Topic, Opts) ->
    PoolSize = ?LOOKUP(buffer_pool_size, Opts,
        ?DEFAULT_TOPIC_POOL_SIZE),
    case ets:insert_new(?ETS_TABLE_TOPIC, {Topic, PoolSize}) of
        false ->
            {error, topic_already_stated};
        true ->
            case flare_metadata:partitions(Topic) of
                {ok, Partitions} ->
                    flare_broker_pool:start(Partitions),
                    flare_compiler:topic_utils(),
                    start_topic_buffers(Topic, Opts, Partitions, PoolSize),
                    ok;
                {error, Reason} ->
                    {error, Reason}
            end
    end.

-spec stop(topic_name()) ->
    ok | {error, atom()}.

stop(Topic) ->
    case flare_utils:ets_lookup_element(?ETS_TABLE_TOPIC, Topic) of
        undefined ->
            {error, topic_not_started};
        PoolSize ->
            case ets:select_delete(?ETS_TABLE_TOPIC, ?MATCH_SPEC(Topic)) of
                0 ->
                    {error, topic_not_started};
                1 ->
                    stop_topic_buffers(Topic, PoolSize),
                    flare_compiler:topic_utils()
            end
    end.

%% private
start_topic_buffers(_Topic, _Opts, _Partitions, 0) ->
    ok;
start_topic_buffers(Topic, Opts, Partitions, N) ->
    Name = flare_topic_utils:server_name(Topic, N),
    Spec = ?CHILD(Name, flare_topic_buffer, [Name, Topic, Opts, Partitions]),
    {ok, _Pid} = supervisor:start_child(?SUPERVISOR, Spec),
    start_topic_buffers(Topic, Opts, Partitions, N - 1).

stop_topic_buffers(_Topic, 0) ->
    ok;
stop_topic_buffers(Topic, N) ->
    Name = flare_topic_utils:server_name(Topic, N),
    ok = supervisor:terminate_child(?SUPERVISOR, Name),
    ok = supervisor:delete_child(?SUPERVISOR, Name),
    stop_topic_buffers(Topic, N - 1).

topic_buffer_msg(Topic, Index, Message) ->
    flare_topic_utils:server_name(Topic, Index) ! Message.
