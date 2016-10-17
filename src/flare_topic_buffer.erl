-module(flare_topic_buffer).
-include("flare_internal.hrl").
-include_lib("shackle/include/shackle.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    init/5,
    produce/2,
    start_link/4
]).

%% sys behavior
-export([
    system_code_change/4,
    system_continue/3,
    system_get_state/1,
    system_terminate/4
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
-spec init(pid(), buffer_name(), topic_name(), topic_opts(),
        partition_tuples()) -> no_return().

init(Parent, Name, Topic, Opts, Partitions) ->
    process_flag(trap_exit, true),
    register(Name, self()),
    proc_lib:init_ack(Parent, {ok, self()}),

    Acks = ?LOOKUP(acks, Opts, ?DEFAULT_TOPIC_ACKS),
    BufferDelay = ?LOOKUP(buffer_delay, Opts,
        ?DEFAULT_TOPIC_BUFFER_DELAY),
    BufferSizeMax = ?LOOKUP(buffer_size, Opts,
        ?DEFAULT_TOPIC_BUFFER_SIZE),
    Compression = flare_utils:compression(?LOOKUP(compression, Opts,
        ?DEFAULT_TOPIC_COMPRESSION)),
    MetadataDelay = ?LOOKUP(metadata_delay, Opts,
        ?DEFAULT_TOPIC_METADATA_DELAY),

    loop(#state {
        acks = Acks,
        buffer_delay = BufferDelay,
        buffer_size_max = BufferSizeMax,
        buffer_timer_ref = timer(BufferDelay, ?MSG_BUFFER_DELAY),
        compression = Compression,
        name = Name,
        metadata_delay = MetadataDelay,
        metadata_timer_ref = timer(MetadataDelay, ?MSG_METADATA_DELAY),
        parent = Parent,
        partitions = Partitions,
        topic = Topic
    }).

-spec produce(pid(), state()) ->
    ok.

produce(Pid, #state {
        acks = Acks,
        buffer = Buffer,
        compression = Compression,
        partitions = Partitions,
        requests = Requests,
        topic = Topic
    }) ->

    Messages = flare_protocol:encode_message_set(lists:reverse(Buffer)),
    Messages2 = flare_utils:compress(Compression, Messages),
    {Partition, PoolName, _} = shackle_utils:random_element(Partitions),
    Request = flare_protocol:encode_produce(Topic, Partition, Messages2,
        Acks, Compression),
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
    InitOpts = [self(), Name, Topic, Opts, Partitions],
    proc_lib:start_link(?MODULE, init, InitOpts).

%% sys callbacks
-spec system_code_change(state(), module(), undefined | term(), term()) ->
    {ok, state()}.

system_code_change(State, _Module, _OldVsn, _Extra) ->
    {ok, State}.

-spec system_continue(pid(), [], state()) ->
    ok.

system_continue(_Parent, _Debug, State) ->
    loop(State).

-spec system_get_state(state()) ->
    {ok, state()}.

system_get_state(State) ->
    {ok, State}.

-spec system_terminate(term(), pid(), [], state()) ->
    none().

system_terminate(Reason, _Parent, _Debug, _State) ->
    exit(Reason).

%% private
async_produce(State) ->
    spawn(?MODULE, produce, [self(), State]).

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
handle_msg({produce, ReqId, Message, Pid}, #state {
        buffer = Buffer,
        buffer_count = BufferCount,
        buffer_size = BufferSize,
        buffer_size_max = SizeMax,
        requests = Requests
    } = State) when (BufferSize + size(Message)) > SizeMax ->

    async_produce(State#state {
        buffer = [Message | Buffer],
        buffer_count = BufferCount + 1,
        buffer_size = BufferSize + size(Message),
        requests = [{ReqId, Pid} | Requests]
    }),

    {ok, State#state {
        buffer = [],
        buffer_count = 0,
        buffer_size = 0,
        requests = []
    }};
handle_msg({produce, ReqId, Message, Pid}, #state {
        buffer = Buffer,
        buffer_count = BufferCount,
        buffer_size = BufferSize,
        requests = Requests
    } = State) ->

    {ok, State#state {
        buffer = [Message | Buffer],
        buffer_count = BufferCount + 1,
        buffer_size = BufferSize + size(Message),
        requests = [{ReqId, Pid} | Requests]
    }};
handle_msg(#cast {
        client = ?CLIENT,
        reply = {ok, {_, _, ErrorCode, _}},
        request_id = ReqId
    }, State) ->

    Response = flare_response:error_code(ErrorCode),
    reply(ReqId, Response),
    maybe_reload_metadata(Response, State);
handle_msg(#cast {
        client = ?CLIENT,
        reply = {error, _Reason} = Error,
        request_id = ReqId
    }, State) ->

    reply(ReqId, Error),
    {ok, State}.

loop(#state {parent = Parent} = State) ->
    receive
        {'EXIT', _Pid, shutdown} ->
            terminate(State);
        {system, From, Request} ->
            sys:handle_system_msg(Request, From, Parent, ?MODULE, [], State);
        Message ->
            {ok, State2} = handle_msg(Message, State),
            loop(State2)
    end.

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

reply([], _Response) ->
    ok;
reply([{_, undefined} | T], Response) ->
    reply(T, Response);
reply([{ReqId, Pid} | T], Response) ->
    Pid ! {ReqId, Response},
    reply(T, Response);
reply(ReqId, Response) ->
    case flare_queue:remove(ReqId) of
        {ok, {_PoolName, Requests}} ->
            reply(Requests, Response);
        {error, not_found} ->
            shackle_utils:warning_msg(?CLIENT,
                "reply error: ~p~n", [not_found]),
            ok
    end.

terminate(#state {
        requests = Requests,
        buffer_timer_ref = BufferTimerRef,
        metadata_timer_ref = MetadataTimerRef
    }) ->

    reply(Requests, {error, shutdown}),
    erlang:cancel_timer(BufferTimerRef),
    erlang:cancel_timer(MetadataTimerRef),
    exit(shutdown).

timer(Time, Msg) ->
    erlang:send_after(Time, self(), Msg).
