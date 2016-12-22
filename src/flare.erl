-module(flare).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    async_produce/2,
    async_produce/3,
    produce/2,
    produce/3,
    receive_response/1,
    receive_response/2
]).

%% public
-spec async_produce(topic_name(), msg()) ->
    {ok, req_id()} | {error, atom()}.

async_produce(Topic, Message) ->
    async_produce(Topic, Message, self()).

-spec async_produce(topic_name(), msg(), pid() | undefined) ->
    {ok, req_id()} | {error, atom()}.

async_produce(Topic, Message, Pid) ->
    case flare_topic:server(Topic) of
        {ok, {BufferSize, Server}} ->
            Size = size(Message),
            case shackle_backlog:check(Server, BufferSize * 4, Size) of
                true ->
                    ReqId = {os:timestamp(), self()},
                    Server ! {produce, ReqId, Message, Size, Pid},
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
    produce(Topic, Message, ?DEFAULT_TIMEOUT).

-spec produce(topic_name(), msg(), pos_integer()) ->
    ok | {error, atom()}.

produce(Topic, Message, Timeout) ->
    case async_produce(Topic, Message, self()) of
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
