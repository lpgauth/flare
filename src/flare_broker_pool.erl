-module(flare_broker_pool).
-include("flare_internal.hrl").

-export([
    start/1
    % stop/1
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
start(Name, #broker {
        host = Host,
        port = Port
    }) ->

    BacklogSize = ?GET_ENV(broker_backlog_size,
        ?DEFAULT_BROKER_BACKLOG_SIZE),
    Ip = binary_to_list(Host),
    PoolSize = ?GET_ENV(broker_pool_size, ?DEFAULT_BROKER_POOL_SIZE),
    PoolStrategy = ?GET_ENV(broker_pool_strategy,
        ?DEFAULT_BROKER_POOL_STRATEGY),
    Reconnect = ?GET_ENV(broker_reconnect, ?DEFAULT_BROKER_RECONNECT),
    ReconnectTimeMax = ?GET_ENV(broker_reconnect_time_max,
        ?DEFAULT_BROKER_RECONNECT_MAX),
    ReconnectTimeMin = ?GET_ENV(broker_reconnect_time_min,
        ?DEFAULT_BROKER_RECONNECT_MIN),

    shackle_pool:start(Name, ?CLIENT, [
        {ip, Ip},
        {port, Port},
        {reconnect, Reconnect},
        {reconnect_time_max, ReconnectTimeMax},
        {reconnect_time_min, ReconnectTimeMin},
        {socket_options, [
            binary,
            {packet, 4},
            {send_timeout, 500},
            {send_timeout_close, true}
        ]}
    ], [
        {backlog_size, BacklogSize},
        {pool_size, PoolSize},
        {pool_strategy, PoolStrategy}
    ]).
