-module(flare_client).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-behavior(shackle_client).
-export([
    init/1,
    setup/2,
    handle_request/2,
    handle_data/2,
    terminate/1
]).

-record(state, {
    request_counter = 0 :: non_neg_integer()
}).

-type state() :: #state {}.

%% shackle_server callbacks
-spec init(undefined) ->
    {ok, state()}.

init(_Opts) ->
    {ok, #state {}}.

-spec setup(inet:socket(), state()) ->
    {ok, state()}.

setup(_Socket, State) ->
    {ok, State}.

-spec handle_request(term(), state()) ->
    {ok, non_neg_integer(), iolist(), state()}.

handle_request({produce, Req}, #state {
        request_counter = RequestCounter
    } = State) ->

    ReqId = request_id(RequestCounter),
    Data = flare_kpro:encode_request(ReqId, Req),

    {ok, ReqId, Data, State#state {
        request_counter = RequestCounter + 1
    }}.

-spec handle_data(binary(), state()) ->
    {ok, [{pos_integer(), term()}], state()}.

handle_data(<<ReqId:32, Rest/binary>>, State) ->
    Response = flare_kpro:decode_produce(Rest),
    {ok, [{ReqId, {flare_response, Response}}], State}.

-spec terminate(state()) -> ok.

terminate(_State) ->
    ok.

%% private
request_id(RequestCounter) ->
    RequestCounter rem ?MAX_REQUEST_ID.
