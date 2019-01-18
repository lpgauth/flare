-module(flare_api_versions).
-include("flare_internal.hrl").

-export([
    init/0,
    produce/0,
    terminate/0
]).

%% public
-spec init() ->
    ok.

init() ->
    foil:new(?MODULE),
    case ?GET_ENV(query_api_versions, true) of
        true ->
            case api_versions() of
                {ok, ApiVersions} ->
                    ProduceRange = find(produce, ApiVersions),
                    ProduceVsn = pick(ProduceRange, ?PRODUCE_VSN_RANGE),
                    foil:insert(?MODULE, produce, ProduceVsn);
                {error, bootstrap_failed} ->
                    error_logger:error_msg("failed to query api versions: ~p~n",
                        [boostrap_failed]),
                    foil:insert(?MODULE, produce, ?PRODUCE_VSN)
            end;
        false ->
            foil:insert(?MODULE, produce, ?KAFKA_0_9_PRODUCE_VSN)
    end,
    foil:load(?MODULE).

-spec produce() ->
    {ok, vsn()} | {error, flare_not_started}.

produce() ->
    case foil:lookup(?MODULE, produce) of
        {ok, Vsn} ->
            {ok, Vsn};
        {error, _} ->
            {error, flare_not_started}
    end.

-spec terminate() ->
    ok.

terminate() ->
    foil:delete(?MODULE).

%% private
api_versions() ->
    Servers = ?GET_ENV(broker_bootstrap_servers,
        ?DEFAULT_BROKER_BOOTSTRAP_SERVERS),
    api_versions(Servers).

api_versions([]) ->
    {error, bootstrap_failed};
api_versions([{Ip, Port} | T]) ->
    Req = flare_kpro:encode_api_versions(),
    Data = flare_kpro:encode_request(0, Req),
    case flare_utils:send_recv(Ip, Port, Data) of
        {ok, <<0:32, Bin/binary>>} ->
            flare_kpro:decode_api_versions(Bin);
        {error, _Reason} ->
            api_versions(T)
    end.

find(ApiKey, [#{
        api_key := ApiKey,
        min_version := MinVersion,
        max_version := Maxversion
    } | _]) ->

    {MinVersion, Maxversion};
find(ApiKey, [_ | T]) ->
    find(ApiKey, T).

pick({_, Max}, {_, Max2}) when Max >= Max2 ->
    Max2;
pick({_, Max}, {_, Max2}) when Max2 >= Max ->
    Max.
