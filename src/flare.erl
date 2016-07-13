-module(flare).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    async_produce/2,
    async_produce/3,
    produce/2,
    produce/3
]).

%% public
-spec async_produce(topic_name(), msg()) ->
    ok | {error, atom()}.

async_produce(Topic, Message) ->
    async_produce(Topic, Message, self()).

-spec async_produce(topic_name(), msg(), pid()) ->
    ok | {error, atom()}.

async_produce(Topic, Message, Pid) ->
    case flare_topic:server(Topic) of
        {ok, Server} ->
            ReqId = {Server, make_ref()},
            Cast = {produce, ReqId, Message, Pid},
            Server ! Cast,
            {ok, ReqId};
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

receive_response(ReqId, Timeout) ->
    receive
        {ReqId, Response} ->
            Response
    after Timeout ->
        {error, timeout}
    end.
