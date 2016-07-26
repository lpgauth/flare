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

-define(SAMPLE_RATE_ERROR, 0.1).
-define(SAMPLE_RATE_OK, 0.005).

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
    topic                  :: topic_name(),
    topic_key              :: binary()
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
        topic = Topic,
        topic_key = topic_key(Topic)
    }).

-spec produce([msg()], requests(), pid(), state()) ->
    ok.

produce(Messages, Requests, Pid, #state {
        acks = Acks,
        buffer_count = BufferCount,
        compression = Compression,
        partitions = Partitions,
        topic = Topic,
        topic_key = TopicKey
    }) ->

    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".batch.call">>], 1, ?SAMPLE_RATE_OK),
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".message.call">>], BufferCount + 1, ?SAMPLE_RATE_OK),
    Timestamp = os:timestamp(),

    Messages2 = flare_protocol:encode_message_set(lists:reverse(Messages)),
    Messages3 = flare_utils:compress(Compression, Messages2),
    {Partition, PoolName, _} = shackle_utils:random_element(Partitions),
    Request = flare_protocol:encode_produce(Topic, Partition, Messages3,
        Acks, Compression),
    Cast = {produce, Request, BufferCount},
    {ok, ReqId} = shackle:cast(PoolName, Cast, Pid),
    flare_queue:add(ReqId, PoolName, Requests),

    Diff = timer:now_diff(os:timestamp(), Timestamp),
    statsderl:timing([<<"flare.produce.">>, TopicKey,
        <<".call">>], Diff, ?SAMPLE_RATE_OK).

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
async_produce(Buffer, Requests, State) ->
    spawn(?MODULE, produce, [Buffer, Requests, self(), State]).

handle_msg(?MSG_BUFFER_DELAY, #state {
        buffer = [],
        buffer_delay = BufferDelay
    } = State) ->

    {ok, State#state {
        buffer_timer_ref = timer(BufferDelay, ?MSG_BUFFER_DELAY)
    }};
handle_msg(?MSG_BUFFER_DELAY, #state {
        buffer = Buffer,
        buffer_delay = BufferDelay,
        requests = Requests
    } = State) ->

    async_produce(Buffer, Requests, State),

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
        buffer_size = BufferSize,
        buffer_size_max = SizeMax,
        requests = Requests
    } = State) when (BufferSize + size(Message)) > SizeMax ->

    async_produce([Message | Buffer], [{ReqId, Pid} | Requests], State),

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
        request = {_, _, Count},
        request_id = ReqId
    }, #state {
        topic_key = TopicKey
    } = State) ->

    Response = flare_response:error_code(ErrorCode),
    reply(ReqId, Response),
    statsderl_produce(Response, TopicKey, Count),
    maybe_reload_metadata(Response, State);
handle_msg(#cast {
        client = ?CLIENT,
        reply = {error, _Reason} = Error,
        request = {_, _, Count},
        request_id = ReqId
    }, #state {
        topic_key = TopicKey
    } = State) ->

    reply(ReqId, Error),
    statsderl_produce(Error, TopicKey, Count),
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

statsderl_produce(ok, TopicKey, Count) ->
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".batch.ok">>], 1, 0.01),
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".message.ok">>], Count, 0.01);
statsderl_produce({error, Reason}, TopicKey, Count) ->
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".batch.error">>], 1, ?SAMPLE_RATE_ERROR),
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".message.error">>], Count, ?SAMPLE_RATE_ERROR),
    ReasonBin = atom_to_binary(Reason, latin1),
    statsderl:increment([<<"flare.produce.">>, TopicKey,
        <<".error.">>, ReasonBin], 1, ?SAMPLE_RATE_ERROR).

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

topic_key(Topic) ->
    binary:replace(Topic, <<".">>, <<"_">>, [global]).
