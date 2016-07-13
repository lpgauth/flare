-module(flare_topic_buffer).
-include("flare_internal.hrl").
-include_lib("shackle/include/shackle.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    init/5,
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

    loop(#state {
        acks = Acks,
        buffer_delay_max = BufferDelayMax,
        buffer_size_max = BufferSizeMax,
        compression = Compression,
        name = Name,
        parent = Parent,
        partitions = Partitions,
        timer_ref = timer(BufferDelayMax),
        topic = Topic
    }).

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
        buffer = Buffer,
        buffer_delay_max = BufferDelayMax,
        name = Name,
        requests = Requests
    } = State) ->

    {ok, ReqId} = produce(Buffer, State),
    flare_queue:add(Name, ReqId, Requests),

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
        name = Name,
        requests = Requests
    } = State) ->

    Buffer2 = [Message | Buffer],
    Requests2 = [{ReqId, Pid} | Requests],

    case BufferSize + iolist_size(Message) of
        X  when X > SizeMax ->
            {ok, ReqId2} = produce(Buffer2, State),
            flare_queue:add(Name, ReqId2, Requests2),

            {ok, State#state {
                buffer = [],
                buffer_count = 0,
                buffer_size = 0,
                requests = []
            }};
        X ->
            {ok, State#state {
                buffer = Buffer2,
                buffer_count = BufferCount + 1,
                buffer_size = X,
                requests = Requests2
            }}
    end;
handle_msg(#cast {
        client = ?CLIENT,
        reply = {ok, {_, _, ErrorCode, _}},
        request_id = ReqId
    }, #state {name = Name} = State) ->

    case flare_response:error_code(ErrorCode) of
        ok ->
            reply_all(Name, ReqId, ok);
        {error, Reason} ->
            % TODO: reload topic metadata on partition errors
            % TODO: retry certain errors
            reply_all(Name, ReqId, {error, Reason})
    end,
    {ok, State};
handle_msg(#cast {
        client = ?CLIENT,
        reply = Reply,
        request_id = ReqId
    }, #state {name = Name} = State) ->

    % TODO: retry certain errors
    reply_all(Name, ReqId, Reply),
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

produce([], _State) ->
    {ok, undefined};
produce(_Messages, #state {partitions = undefined}) ->
    {ok, undefined};
produce(Messages, #state {
        acks = Acks,
        compression = Compression,
        partitions = Partitions,
        topic = Topic
    }) ->

    Messages2 = flare_protocol:encode_message_set(lists:reverse(Messages)),
    Messages3 = flare_utils:compress(Compression, Messages2),
    {Partition, PoolName, _} = shackle_utils:random_element(Partitions),
    Request = flare_protocol:encode_produce(Topic, Partition, Messages3,
        Acks, Compression),
    shackle:cast(PoolName, {produce, Request}).

reply(Pid, ReqId, Reply) ->
    Pid ! {ReqId, Reply}.

reply_all(Name, ExtReqId, Reply) ->
    case flare_queue:remove(Name, ExtReqId) of
        {ok, Requests} ->
            [reply(Pid, ReqId, Reply) || {ReqId, Pid} <- Requests];
        {error, not_found} ->
            ok
    end.

terminate(#state {
        buffer = Buffer,
        timer_ref = TimerRef
    } = State) ->

    erlang:cancel_timer(TimerRef),
    produce(Buffer, State),
    exit(shutdown).

timer(Time) ->
    erlang:send_after(Time, self(), ?MSG_TIMEOUT).
