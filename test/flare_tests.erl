-module(flare_tests).
-include_lib("eunit/include/eunit.hrl").
-include_lib("flare/include/flare.hrl").

%% runners
flare_test_() ->
    {setup,
        fun () -> setup() end,
        fun (_) -> cleanup() end,
        fun produce_subtest/0
    }.

%% tests
produce_subtest() ->
    Topic = <<"test">>,
    {error, topic_not_started} = produce(Topic),
    ok = flare_topic:start(Topic, [
        {buffer_delay, 500},
        {compression, snappy}
    ]),
    {error, topic_already_stated} = flare_topic:start(Topic),
    ok = produce(Topic),
    ok = produce(Topic),
    [async_produce(Topic, undefined) || _ <- lists:seq(1, 10000)],
    {ok, ReqId} = async_produce(Topic, self()),
    {error, timeout} = flare:receive_response(ReqId, 0),
    ok = flare:receive_response(ReqId, 5000),
    ok = flare_topic:stop(Topic),
    {error, topic_not_started} = flare_topic:stop(Topic),

    Topic2 = <<"test2">>,
    {error, leader_not_available} = flare_topic:start(Topic2),
    {error, topic_not_started} = produce(Topic2).

% utils
async_produce(Topic, Pid) ->
    flare:async_produce(Topic, flare_utils:timestamp(), <<"key">>, <<"value">>,
        [{<<"hkey">>, <<"hvalue">>}], Pid).

cleanup() ->
    flare_app:stop().

produce(Topic) ->

    flare:produce(Topic, flare_utils:timestamp(), <<"key2">>, <<"value2">>,
        [{<<"hkey2">>, <<"hvalue2">>}], 5000).

setup() ->
    error_logger:tty(false),
    flare_app:start().
