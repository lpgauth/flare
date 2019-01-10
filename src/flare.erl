-module(flare).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    async_produce/2,
    async_produce/3,
    async_produce/4,
    produce/2,
    produce/3,
    produce/4,
    receive_response/1,
    receive_response/2
]).

-type timestamp() :: pos_integer().

%% public
-spec async_produce(topic_name(), msg()) ->
    {ok, req_id()} | {error, atom()}.

async_produce(Topic, Message) ->
    async_produce(Topic, Message, flare_utils:timestamp()).

-spec async_produce(topic_name(), msg(), timestamp()) ->
    {ok, req_id()} | {error, atom()}.

async_produce(Topic, Message, Timestamp) ->
    async_produce(Topic, Message, Timestamp, self()).

-spec async_produce(topic_name(), msg(), timestamp(),
    pid() | undefined) -> {ok, req_id()} | {error, atom()}.

async_produce(Topic, Message, Timestamp, Pid) ->
    case flare_topic:server(Topic) of
        {ok, {BufferSize, Server}} ->
            Size = size(Message),
            case shackle_backlog:check(Server, BufferSize * 4, Size) of
                true ->
                    ReqId = {os:timestamp(), self()},
                    Request = {produce, ReqId, Message, Timestamp, Pid, Size},
                    Server ! Request,
                    {ok, ReqId};
                false ->
                    {error, backlog_full}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

-spec produce(topic_name(), msg()) ->
    ok | {error, atom()}.

produce(Topic, Message) ->
    produce(Topic, Message, flare_utils:timestamp()).

-spec produce(topic_name(), msg(), timestamp()) ->
    ok | {error, atom()}.

produce(Topic, Message, Timestmap) ->
    produce(Topic, Message, Timestmap, ?DEFAULT_TIMEOUT).

-spec produce(topic_name(), msg(), timestamp(), pos_integer()) ->
    ok | {error, atom()}.

produce(Topic, Message, Timestamp, Timeout) ->
    case async_produce(Topic, Message, Timestamp, self()) of
        {ok, ReqId} ->
            receive_response(ReqId, Timeout);
        {error, Reason} ->
            {error, Reason}
    end.

-spec receive_response(req_id()) ->
    ok | {error, atom()}.

receive_response(ReqId) ->
    receive_response(ReqId, ?DEFAULT_TIMEOUT).

-spec receive_response(req_id(), pos_integer()) ->
    ok | {error, atom()}.

receive_response(ReqId, Timeout) ->
    receive
        {ReqId, Response} ->
            Response
    after Timeout ->
        {error, timeout}
    end.
