-module(flare_broker_pool).
-include("flare_internal.hrl").

-export([
    start/1
]).

%% public
-spec start([{partition_id(), atom(), broker()}]) ->
    ok.

start([]) ->
    ok;
start([{_PartitionId, Name, Broker} | T]) ->
    start(Name, Broker),
    start(T).

%% private
start(Name, #{host := Host, port := Port}) ->
    {ClientConfig, PoolConfig} = get_shackle_parameters(binary_to_list(Host), Port),
    shackle_pool:start(Name, ?CLIENT, ClientConfig, PoolConfig).

get_shackle_parameters(IP, Port) ->
    %% Flare maps the shackle options using "broker_" prefix, so use the
    %% option name mapping
    shackle_utils:merge_options(?APP, [
        {ip, IP},
        {port, Port},
        {protocol, shackle_udp},
        {reconnect, ?DEFAULT_BROKER_RECONNECT},
        {reconnect_time_max, ?DEFAULT_BROKER_RECONNECT_MAX},
        {reconnect_time_min, ?DEFAULT_BROKER_RECONNECT_MIN},
        {pool_size, ?DEFAULT_BROKER_POOL_SIZE},
        {pool_strategy, ?DEFAULT_BROKER_POOL_STRATEGY},
        {backlog_size, ?DEFAULT_BROKER_BACKLOG_SIZE},
        {socket_options, ?SOCKET_OPTIONS}
    ], #{
         backlog_size => broker_backlog_size,
         pool_size => broker_pool_size,
         pool_strategy => broker_pool_strategy,
         reconnect => broker_reconnect,
         reconnect_time_max => broker_reconnect_time_max,
         reconnect_time_min => broker_reconnect_time_min
    }).