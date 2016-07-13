-module(flare_tests).
-include_lib("eunit/include/eunit.hrl").
-include_lib("flare/include/flare.hrl").

%% runners
flare_test_() ->
    {setup,
        fun () -> setup() end,
        fun (_) -> cleanup() end,
    [
        fun produce_subtest/0
    ]}.

%% tests
produce_subtest() ->
    Topic = <<"test">>,
    ok = flare_topic:start(Topic),
    {error, topic_already_stated} = flare_topic:start(Topic),
    ok = flare:produce(Topic, <<"event1">>, 5000),
    ok = flare:produce(Topic, <<"event1">>),
    [flare:async_produce(Topic, <<"event1">>, undefined)
        || _ <- lists:seq(1, 10000)],
    {ok, ReqId} = flare:async_produce(Topic, <<"event1">>),
    {error, timeout} = flare:receive_response(ReqId, 0),
    ok = flare:receive_response(ReqId),
    ok = flare_topic:stop(Topic),
    {error, topic_not_started} = flare_topic:stop(Topic),

    Topic2 = <<"test2">>,
    {error, no_metadata} = flare_topic:start(Topic2),
    {error, topic_not_started} = flare:produce(Topic2, <<"event2">>, 5000).

% utils
cleanup() ->
    flare_app:stop().

setup() ->
    error_logger:tty(false),
    flare_app:start().
