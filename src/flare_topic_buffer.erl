-module(flare_topic_buffer).
-include("flare_internal.hrl").
-include_lib("shackle/include/shackle.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    produce/2,
    start_link/4
]).

-behavior(metal).
-export([
    init/3,
    handle_msg/2,
    terminate/2
]).

-record(state, {
    acks                   :: 1..65535,
    buffer = []            :: list(),
    buffer_count       = 0 :: non_neg_integer(),
    buffer_delay           :: pos_integer(),
    buffer_size        = 0 :: non_neg_integer(),
    buffer_size_max        :: undefined | pos_integer(),
    buffer_timer_ref       :: undefined | reference(),
    compression            :: compression(),
    msg_api_version        :: msg_api_version(),
    metadata_delay         :: pos_integer(),
    metadata_timer_ref     :: undefined | reference(),
    name                   :: atom(),
    parent                 :: pid(),
    partitions             :: undefined | list(),
    requests = []          :: requests(),
    topic                  :: topic_name()
}).

-type state() :: #state {}.

-define(MSG_BUFFER_DELAY, buffer_timeout).
-define(MSG_METADATA_DELAY, metadata_timeout).

%% public
-spec produce(pid(), state()) ->
    ok.

produce(Pid, #state {
        acks = Acks,
        buffer = Buffer,
        compression = Compression,
        msg_api_version = MsgApiVersion,
        partitions = Partitions,
        requests = Requests,
        topic = Topic
    }) ->

    Messages = flare_protocol:encode_message_set(lists:reverse(Buffer),
        ?COMPRESSION_NONE, MsgApiVersion),
    Messages2 = flare_utils:compress(Compression, Messages),
    {Partition, PoolName, _} = shackle_utils:random_element(Partitions),
    Request = flare_protocol:encode_produce(Topic, Partition, Messages2,
        Acks, Compression, MsgApiVersion),

    case shackle:cast(PoolName, {produce, Request}, Pid) of
        {ok, ReqId} ->
            flare_queue:add(ReqId, PoolName, Requests);
        {error, Reason} ->
            shackle_utils:warning_msg(?CLIENT,
                "shackle cast failed: ~p~n", [Reason])
    end.

-spec start_link(buffer_name(), topic_name(), topic_opts(),
    partition_tuples()) -> {ok, pid()}.

start_link(Name, Topic, Opts, Partitions) ->
    Args = {Topic, Opts, Partitions},
    metal:start_link(?MODULE, Name, Args).

%% metal_server callbacks
-spec init(server_name(), pid(), term()) ->
    no_return().

init(Name, Parent, Opts) ->
    {Topic, TopicOpts, Partitions} = Opts,
    ok = shackle_backlog:new(Name),

    Acks = ?LOOKUP(acks, TopicOpts, ?DEFAULT_TOPIC_ACKS),
    BufferDelay = ?LOOKUP(buffer_delay, TopicOpts,
        ?DEFAULT_TOPIC_BUFFER_DELAY),
    BufferSizeMax = ?LOOKUP(buffer_size, TopicOpts,
        ?DEFAULT_TOPIC_BUFFER_SIZE),
    Compression = flare_utils:compression(?LOOKUP(compression, TopicOpts,
        ?DEFAULT_TOPIC_COMPRESSION)),
    MetadataDelay = ?LOOKUP(metadata_delay, TopicOpts,
        ?DEFAULT_TOPIC_METADATA_DELAY),
    MsgApiVersion = ?LOOKUP(msg_api_version,
        TopicOpts, ?DEFAULT_MESSAGE_API_VERSION),

    {ok, #state {
        acks = Acks,
        buffer_delay = BufferDelay,
        buffer_size_max = BufferSizeMax,
        buffer_timer_ref = timer(BufferDelay, ?MSG_BUFFER_DELAY),
        compression = Compression,
        msg_api_version = MsgApiVersion,
        metadata_delay = MetadataDelay,
        metadata_timer_ref = timer(MetadataDelay, ?MSG_METADATA_DELAY),
        name = Name,
        parent = Parent,
        partitions = Partitions,
        topic = Topic
    }}.

-spec handle_msg(term(), state()) ->
    {ok, term()}.

handle_msg(?MSG_BUFFER_DELAY, #state {
        buffer = [],
        buffer_delay = BufferDelay
    } = State) ->

    {ok, State#state {
        buffer_timer_ref = timer(BufferDelay, ?MSG_BUFFER_DELAY)
    }};
handle_msg(?MSG_BUFFER_DELAY, #state {
        buffer_delay = BufferDelay
    } = State) ->

    async_produce(State),

    {ok, State#state {
        buffer = [],
        buffer_count = 0,
        buffer_size = 0,
        requests = [],
        buffer_timer_ref = timer(BufferDelay, ?MSG_BUFFER_DELAY)
    }};
handle_msg(?MSG_METADATA_DELAY, #state {
        metadata_delay = MetadataDelay,
        topic = Topic
    } = State) ->

    case flare_metadata:partitions(Topic) of
        {ok, Partitions} ->
            flare_broker_pool:start(Partitions),

            {ok, State#state {
                metadata_timer_ref = timer(MetadataDelay, ?MSG_METADATA_DELAY),
                partitions = Partitions
            }};
        {error, Reason} ->
            shackle_utils:warning_msg(?CLIENT,
                "metadata reload failed: ~p~n", [Reason]),
            {ok, State#state {
                metadata_timer_ref = timer(MetadataDelay, ?MSG_METADATA_DELAY)
            }}
    end;
handle_msg({produce, ReqId, Message, Size, Pid}, #state {
        buffer = Buffer,
        buffer_count = BufferCount,
        buffer_size = BufferSize,
        buffer_size_max = SizeMax,
        name = Name,
        requests = Requests
    } = State) when (BufferSize + Size) > SizeMax ->

    async_produce(State#state {
        buffer = [Message | Buffer],
        buffer_count = BufferCount + 1,
        buffer_size = BufferSize + Size,
        requests = [{ReqId, Pid} | Requests]
    }),

    shackle_backlog:decrement(Name, Size),

    {ok, State#state {
        buffer = [],
        buffer_count = 0,
        buffer_size = 0,
        requests = []
    }};
handle_msg({produce, ReqId, Message, Size, Pid}, #state {
        buffer = Buffer,
        buffer_count = BufferCount,
        buffer_size = BufferSize,
        name = Name,
        requests = Requests
    } = State) ->

    shackle_backlog:decrement(Name, Size),

    {ok, State#state {
        buffer = [Message | Buffer],
        buffer_count = BufferCount + 1,
        buffer_size = BufferSize + Size,
        requests = [{ReqId, Pid} | Requests]
    }};
handle_msg({#cast {
        client = ?CLIENT,
        request_id = ReqId
    }, {ok, {_, _, ErrorCode, _}}}, State) ->

    Response = flare_response:error_code(ErrorCode),
    reply_all(ReqId, Response),
    maybe_reload_metadata(Response, State);
handle_msg({#cast {
        client = ?CLIENT,
        request_id = ReqId
    }, {error, _Reason} = Error}, State) ->

    reply_all(ReqId, Error),
    {ok, State}.

-spec terminate(term(), term()) ->
    ok.

terminate(_Reason, #state {
        requests = Requests,
        buffer_timer_ref = BufferTimerRef,
        metadata_timer_ref = MetadataTimerRef
    }) ->

    reply_all(Requests, {error, shutdown}),
    erlang:cancel_timer(BufferTimerRef),
    erlang:cancel_timer(MetadataTimerRef),
    ok.

%% private
async_produce(State) ->
    spawn(?MODULE, produce, [self(), State]).

maybe_reload_metadata({error, not_leader_for_partition}, State) ->
    reload_metatadata(State);
maybe_reload_metadata({error, unknown_topic_or_partition}, State) ->
    reload_metatadata(State);
maybe_reload_metadata(_, State) ->
    {ok, State}.

reload_metatadata(#state {
        metadata_timer_ref = MetadataTimerRef
    } = State) ->

    erlang:cancel_timer(MetadataTimerRef),
    handle_msg(?MSG_METADATA_DELAY, State).

reply_all([], _Response) ->
    ok;
reply_all([{_, undefined} | T], Response) ->
    reply_all(T, Response);
reply_all([{ReqId, Pid} | T], Response) ->
    Pid ! {ReqId, Response},
    reply_all(T, Response);
reply_all(ReqId, Response) ->
    case flare_queue:remove(ReqId) of
        {ok, {_PoolName, Requests}} ->
            reply_all(Requests, Response);
        {error, not_found} ->
            shackle_utils:warning_msg(?CLIENT,
                "reply error: ~p~n", [not_found]),
            ok
    end.

timer(Time, Msg) ->
    erlang:send_after(Time, self(), Msg).
