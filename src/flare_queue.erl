-module(flare_queue).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

%% internal
-export([
    add/3,
    init/0,
    remove/1
]).

%% internal
-spec add(ext_req_id(), atom(), requests()) ->
    ok.
add(ExtReqId, PoolName, Requests) ->
    ets:insert_new(?ETS_TABLE_QUEUE, {ExtReqId, {PoolName, Requests}}),
    ok.

-spec init() ->
    ok.

init() ->
    ets_new(?ETS_TABLE_QUEUE),
    ok.

-spec remove(ext_req_id()) ->
    {ok, {atom(), requests()}} | {error, not_found}.

remove(ExtReqId) ->
    case ets_take(?ETS_TABLE_QUEUE, ExtReqId) of
        [] ->
            {error, not_found};
        [{_, Requests}] ->
            {ok, Requests}
    end.

%% private
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
