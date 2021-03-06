-include("flare.hrl").

%% macros
-define(APP, flare).
-define(CHILD(Name, Mod, Args), {Name, {Mod, start_link, Args}, permanent, 5000, worker, [Mod]}).
-define(CLIENT, flare_client).
-define(GET_ENV(Key), ?GET_ENV(Key, undefined)).
-define(GET_ENV(Key, Default), application:get_env(?APP, Key, Default)).
-define(LOOKUP(Key, List), ?LOOKUP(Key, List, undefined)).
-define(LOOKUP(Key, List, Default), shackle_utils:lookup(Key, List, Default)).
-define(MATCH_SPEC(Name), [{{Name, '_'}, [], [true]}]).
-define(SOCKET_OPTIONS, [
    binary,
    {buffer, 65535},
    {nodelay, true},
    {packet, 4},
    {send_timeout, 5000},
    {send_timeout_close, true}
]).
-define(SUPERVISOR, flare_sup).
-define(TIMEOUT, 5000).

%% defaults
-define(DEFAULT_BROKER_BOOTSTRAP_SERVERS, [{"127.0.0.1", 9092}]).
-define(DEFAULT_BROKER_BACKLOG_SIZE, 1024).
-define(DEFAULT_BROKER_POOL_SIZE, 4).
-define(DEFAULT_BROKER_POOL_STRATEGY, random).
-define(DEFAULT_BROKER_RECONNECT, true).
-define(DEFAULT_BROKER_RECONNECT_MAX, timer:minutes(2)).
-define(DEFAULT_BROKER_RECONNECT_MIN, timer:seconds(10)).
-define(DEFAULT_TOPIC_ACKS, 1).
-define(DEFAULT_TOPIC_BUFFER_DELAY, timer:seconds(1)).
-define(DEFAULT_TOPIC_BUFFER_SIZE, 100000).
-define(DEFAULT_TOPIC_COMPRESSION, gzip).
-define(DEFAULT_TOPIC_METADATA_DELAY, timer:minutes(5)).
-define(DEFAULT_TOPIC_POOL_SIZE, 2).

%% ETS tables
-define(ETS_TABLE_QUEUE, flare_queue).
