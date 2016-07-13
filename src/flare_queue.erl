-module(flare_queue).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

%% internal
-export([
    add/3,
    clear/1,
    init/0,
    remove/2
]).

%% internal
-spec add(buffer_name(), ext_req_id() | undefined, requests()) ->
    ok.

add(_BufferName, undefined, _Requests) ->
    ok;
add(BufferName, ExtReqId, Requests) ->
    Object = {{BufferName, ExtReqId}, Requests},
    ets:insert(?ETS_TABLE_QUEUE, Object),
    ok.

-spec clear(buffer_name()) ->
    [requests()].

clear(BufferName) ->
    Match = {{BufferName, '_'}, '_'},
    case ets_match_take(?ETS_TABLE_QUEUE, Match) of
        [] ->
            [];
        Objects ->
            [Request || {_, Request} <- Objects]
    end.

-spec init() ->
    ok.

init() ->
    ets_new(?ETS_TABLE_QUEUE),
    ok.

-spec remove(buffer_name(), ext_req_id()) ->
    {ok, requests()} | {error, not_found}.

remove(BufferName, ExtReqId) ->
    case ets_take(?ETS_TABLE_QUEUE, {BufferName, ExtReqId}) of
        [] ->
            {error, not_found};
        [{_, Requests}] ->
            {ok, Requests}
    end.

%% private
ets_match_take(Tid, Match) ->
    case ets:match_object(Tid, Match) of
        [] ->
            [];
        Objects ->
            ets:match_delete(Tid, Match),
            Objects
    end.

ets_new(Tid) ->
    ets:new(Tid, [
        named_table,
        public,
        {read_concurrency, true},
        {write_concurrency, true}
    ]).

-ifdef(ETS_TAKE).

ets_take(Tid, Key) ->
    ets:take(Tid, Key).

-else.

ets_take(Tid, Key) ->
    case ets:lookup(Tid, Key) of
        [] ->
            [];
        Objects ->
            ets:delete(Tid, Key),
            Objects
    end.

-endif.
