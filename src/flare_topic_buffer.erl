-module(flare_topic_buffer).
-include("flare_internal.hrl").
-include_lib("shackle/include/shackle.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    init/5,
    produce/4,
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
    acks             :: 1..65535,
    buffer = []      :: list(),
    buffer_count = 0 :: non_neg_integer(),
    buffer_delay_max :: pos_integer(),
    buffer_size = 0  :: non_neg_integer(),
    buffer_size_max  :: undefined | pos_integer(),
    compression      :: compression(),
    partitions       :: undefined | list(),
    name             :: atom(),
    parent           :: pid(),
    requests = []    :: requests(),
    retries          :: non_neg_integer(),
    timer_ref        :: undefined | reference(),
    topic            :: topic_name()
}).

-type state() :: #state {}.

%% public
-spec init(pid(), buffer_name(), topic_name(), topic_opts(),
        partition_tuples()) -> no_return().

init(Parent, Name, Topic, Opts, Partitions) ->
    process_flag(trap_exit, true),
    register(Name, self()),
    proc_lib:init_ack(Parent, {ok, self()}),

    Acks = ?LOOKUP(acks, Opts, ?DEFAULT_TOPIC_ACKS),
    BufferDelayMax = ?LOOKUP(buffer_delay, Opts,
        ?DEFAULT_TOPIC_BUFFER_DELAY),
    BufferSizeMax = ?LOOKUP(buffer_size, Opts,
        ?DEFAULT_TOPIC_BUFFER_SIZE),
    Compression = flare_utils:compression(?LOOKUP(compression, Opts,
        ?DEFAULT_TOPIC_COMPRESSION)),
    Retries = ?LOOKUP(retries, Opts,
        ?DEFAULT_TOPIC_RETRIES),

    loop(#state {
        acks = Acks,
        buffer_delay_max = BufferDelayMax,
        buffer_size_max = BufferSizeMax,
        compression = Compression,
        name = Name,
        parent = Parent,
        partitions = Partitions,
        retries = Retries,
        timer_ref = timer(BufferDelayMax),
        topic = Topic
    }).

-spec produce([msg()], requests(), pid(), state()) ->
    ok.

produce(Messages, Requests, Pid, #state {
        acks = Acks,
        compression = Compression,
        partitions = Partitions,
        retries = Retries,
        topic = Topic
    }) ->

    Messages2 = flare_protocol:encode_message_set(lists:reverse(Messages)),
    Messages3 = flare_utils:compress(Compression, Messages2),
    {Partition, PoolName, _} = shackle_utils:random_element(Partitions),
    Request = flare_protocol:encode_produce(Topic, Partition, Messages3,
        Acks, Compression),
    {ok, ReqId} = shackle:cast(PoolName, {produce, Request, Retries}, Pid),
    flare_queue:add(ReqId, PoolName, Requests).

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
handle_msg(?MSG_TIMEOUT, #state {
        buffer = [],
        buffer_delay_max = BufferDelayMax
    } = State) ->

    {ok, State#state {
        timer_ref = timer(BufferDelayMax)
    }};
handle_msg(?MSG_TIMEOUT, #state {
        buffer = Buffer,
        buffer_delay_max = BufferDelayMax,
        requests = Requests
    } = State) ->

    spawn(?MODULE, produce, [Buffer, Requests, self(), State]),

    {ok, State#state {
        buffer = [],
        buffer_count = 0,
        buffer_size = 0,
        requests = [],
        timer_ref = timer(BufferDelayMax)
    }};
handle_msg({produce, ReqId, Message, Pid}, #state {
        buffer = Buffer,
        buffer_count = BufferCount,
        buffer_size = BufferSize,
        buffer_size_max = SizeMax,
        requests = Requests
    } = State) ->

    Buffer2 = [Message | Buffer],
    Requests2 = [{ReqId, Pid} | Requests],

    case BufferSize + iolist_size(Message) of
        Size when Size > SizeMax ->
            spawn(?MODULE, produce, [Buffer2, Requests2, self(), State]),

            {ok, State#state {
                buffer = [],
                buffer_count = 0,
                buffer_size = 0,
                requests = []
            }};
        Size ->
            {ok, State#state {
                buffer = Buffer2,
                buffer_count = BufferCount + 1,
                buffer_size = Size,
                requests = Requests2
            }}
    end;
handle_msg(#cast {
        client = ?CLIENT,
        reply = {ok, {_, _, ErrorCode, _}},
        request = Request,
        request_id = ReqId
    }, State) ->

    Response = flare_response:error_code(ErrorCode),
    reply_or_retry(ReqId, Request, Response),
    {ok, State};
handle_msg(#cast {
        client = ?CLIENT,
        reply = {error, _Reason} = Error,
        request = Request,
        request_id = ReqId
    }, State) ->

    reply_or_retry(ReqId, Request, Error),
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

reply(ExtReqId, Reply) ->
    case flare_queue:remove(ExtReqId) of
        {ok, {_PoolName, Requests}} ->
            reply_all(Requests, Reply);
        {error, not_found} ->
            shackle_utils:warning_msg(?CLIENT,
                "reply error: ~p~n", [not_found]),
            ok
    end.

reply_all([], _Reply) ->
    ok;
reply_all([{_, undefined} | T], Reply) ->
    reply_all(T, Reply);
reply_all([{ReqId, Pid} | T], Reply) ->
    Pid ! {ReqId, Reply},
    reply_all(T, Reply).

reply_or_retry(ExtReqId, _, ok) ->
    reply(ExtReqId, ok);
reply_or_retry(ExtReqId, Request, {error, Reason} = Error) ->
    case Reason of
        invalid_required_acks ->
            reply(ExtReqId, Error);
        no_socket ->
            retry(ExtReqId, Request, Error);
        socket_closed ->
            retry(ExtReqId, Request, Error);
        unknown ->
            reply(ExtReqId, Error);
        _ ->
            shackle_utils:warning_msg(?CLIENT,
                "unhandled error_code: ~p~n", [Reason]),
            reply(ExtReqId, Error)
    end.

retry(ExtReqId, {produce, _, 0}, Error) ->
    reply(ExtReqId, Error);
retry(ExtReqId, {produce, Request, N}, _) when is_integer(N) ->
    case flare_queue:remove(ExtReqId) of
        {ok, {PoolName, Requests}} ->
            {ok, ExtReqId2} = shackle:cast(PoolName, {produce, Request, N - 1}),
            flare_queue:add(ExtReqId2, PoolName, Requests);
        {error, not_found} ->
            shackle_utils:warning_msg(?CLIENT,
                "retry error: ~p~n", [not_found]),
            ok
    end.

terminate(#state {
        requests = Requests,
        timer_ref = TimerRef
    }) ->

    reply_all(Requests, {error, shutdown}),
    erlang:cancel_timer(TimerRef),
    exit(shutdown).

timer(Time) ->
    erlang:send_after(Time, self(), ?MSG_TIMEOUT).
