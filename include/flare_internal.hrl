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
    {packet, 4},
    {send_timeout, 50},
    {send_timeout_close, true}
]).
-define(SUPERVISOR, flare_sup).
-define(TIMEOUT, 5000).

%% defaults
-define(DEFAULT_BROKER_BOOTSTRAP_SERVERS, [{"127.0.0.1", 9092}]).
-define(DEFAULT_BROKER_BACKLOG_SIZE, 1024).
-define(DEFAULT_BROKER_POOL_SIZE, 2).
-define(DEFAULT_BROKER_POOL_STRATEGY, random).
-define(DEFAULT_BROKER_RECONNECT, true).
-define(DEFAULT_BROKER_RECONNECT_MAX, 120000).
-define(DEFAULT_BROKER_RECONNECT_MIN, none).
-define(DEFAULT_TIMEOUT, 1000).
-define(DEFAULT_TOPIC_ACKS, 1).
-define(DEFAULT_TOPIC_BUFFER_DELAY, 1000).
-define(DEFAULT_TOPIC_BUFFER_SIZE, 10000).
-define(DEFAULT_TOPIC_COMPRESSION, snappy).
-define(DEFAULT_TOPIC_METADATA_DELAY, 60000).
-define(DEFAULT_TOPIC_POOL_SIZE, 2).
-define(DEFAULT_TOPIC_RETRIES, 3).

%% ETS tables
-define(ETS_TABLE_QUEUE, flare_queue).
-define(ETS_TABLE_TOPIC, flare_topic).
