-module(flare).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    async_produce/6,
    produce/6,
    receive_response/2
]).

%% public
-spec async_produce(topic(), timestamp(), key(), value(), headers(),
    pid() | undefined) -> {ok, req_id()} | {error, atom()}.

async_produce(Topic, Timestamp, Key, Value, Headers, Pid) ->
    case flare_topic:server(Topic) of
        {ok, {BufferSize, Server}} ->
            {Msg, Size} = flare_utils:msg(Timestamp, Key, Value, Headers),
            case shackle_backlog:check(shackle_backlog_flare_topic, Server,
                    BufferSize * 4, Size) of
                true ->
                    ReqId = {os:timestamp(), self()},
                    Server ! {produce, ReqId, Msg, Size, Pid},
                    {ok, ReqId};
                false ->
                    TopicKey = flare_utils:topic_key(Topic),
                    statsderl:increment([<<"flare.produce.">>, TopicKey,
                        <<".backlog_full">>], 1, 0.01),
                    {error, backlog_full}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

-spec produce(topic(), timestamp(), key(), value(), headers(),
    timeout()) -> {ok, req_id()} | {error, atom()}.

produce(Topic, Timestamp, Key, Value, Headers, Timeout) ->
    case async_produce(Topic, Timestamp, Key, Value, Headers, self()) of
        {ok, ReqId} ->
            receive_response(ReqId, Timeout);
        {error, Reason} ->
            {error, Reason}
    end.

-spec receive_response(req_id(), timeout()) ->
    ok | {error, atom()}.

receive_response(ReqId, Timeout) ->
    receive
        {ReqId, Response} ->
            Response
    after Timeout ->
        {error, timeout}
    end.
