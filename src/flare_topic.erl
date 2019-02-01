-module(flare_topic).
-include("flare_internal.hrl").

-ignore_xref([
    {flare_topic_foil, lookup, 1}
]).

-compile(inline).
-compile({inline_size, 512}).

-export([
    init/0,
    server/1,
    start/1,
    start/2,
    stop/1,
    terminate/0
]).

%% public
-spec init() ->
    ok.

init() ->
    foil:new(?MODULE),
    foil:load(?MODULE).

-spec server(topic()) ->
    {ok, {buffer_size(), buffer_name()}} | {error, atom()}.

server(Topic) ->
    try flare_topic_foil:lookup(Topic) of
        {ok, {BufferSize, PoolSize}} ->
            N = shackle_utils:random(PoolSize),
            {ok, ServerName} = flare_topic_foil:lookup({Topic, N}),
            {ok, {BufferSize, ServerName}};
        {error, key_not_found} ->
            {error, topic_not_started}
    catch
        error:undef ->
            {error, flare_not_started}
    end.

-spec start(topic()) ->
    ok | {error, atom()}.

start(Topic) ->
    start(Topic, []).

-spec start(topic(), [topic_opt()]) ->
    ok | {error, atom()}.

start(Topic, Opts) ->
    BufferSize = ?LOOKUP(buffer_size, Opts, ?DEFAULT_TOPIC_BUFFER_SIZE),
    PoolSize = ?LOOKUP(pool_size, Opts, ?DEFAULT_TOPIC_POOL_SIZE),

    case foil:lookup(?MODULE, Topic) of
        {ok, _} ->
            {error, topic_already_stated};
        {error, key_not_found} ->
            foil:insert(?MODULE, Topic, {BufferSize, PoolSize}),
            foil:load(?MODULE),
            case flare_metadata:partitions(Topic) of
                {ok, Partitions} ->
                    flare_broker_pool:start(Partitions),
                    start_topic_buffers(Topic, Opts, Partitions, PoolSize),
                    [foil:insert(?MODULE, {Topic, I}, name(Topic, I)) ||
                        I <- lists:seq(1, PoolSize)],
                    foil:load(?MODULE),
                    ok;
                {error, Reason} ->
                    foil:delete(?MODULE, Topic),
                    foil:load(?MODULE),
                    {error, Reason}
            end;
        {error, _} ->
            {error, flare_not_started}
    end.

-spec stop(topic()) ->
    ok | {error, atom()}.

stop(Topic) ->
    case foil:lookup(?MODULE, Topic) of
        {ok, {_BufferSize, PoolSize}} ->
            stop_topic_buffers(Topic, PoolSize),
            [foil:delete(?MODULE, name(Topic, I)) ||
                I <- lists:seq(1, PoolSize)],
            foil:delete(?MODULE, Topic),
            foil:load(?MODULE);
        {error, key_not_found} ->
            {error, topic_not_started};
        {error, _} ->
            {error, flare_not_started}
    end.

-spec terminate() ->
    ok.

terminate() ->
    foil:delete(?MODULE).

%% private
name(Topic, Index) ->
    list_to_atom("flare_topic_" ++ binary_to_list(Topic) ++
        "_" ++ integer_to_list(Index)).

start_topic_buffers(_Topic, _Opts, _Partitions, 0) ->
    ok;
start_topic_buffers(Topic, Opts, Partitions, N) ->
    Name = name(Topic, N),
    Spec = ?CHILD(Name, flare_topic_buffer, [Name, Topic, Opts, Partitions]),
    {ok, _Pid} = supervisor:start_child(?SUPERVISOR, Spec),
    start_topic_buffers(Topic, Opts, Partitions, N - 1).

stop_topic_buffers(_Topic, 0) ->
    ok;
stop_topic_buffers(Topic, N) ->
    Name = name(Topic, N),
    ok = supervisor:terminate_child(?SUPERVISOR, Name),
    ok = supervisor:delete_child(?SUPERVISOR, Name),
    stop_topic_buffers(Topic, N - 1).
