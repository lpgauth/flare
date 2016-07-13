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
    [flare:async_produce(Topic, <<"event1">>) || _ <- lists:seq(1, 10000)],
    ok = flare_topic:stop(Topic),
    {error, topic_not_started} = flare_topic:stop(Topic),

    Topic2 = <<"test2">>,
    ok = flare_topic:start(Topic2),
    ok = flare:produce(Topic2, <<"event2">>, 5000),
    ok = flare_topic:stop(Topic2),

    Topic3 = <<"test3">>,
    {error, topic_not_started} = flare:produce(Topic3, <<"event3">>).

% utils
cleanup() ->
    flare_app:stop().

setup() ->
    error_logger:tty(false),
    flare_app:start().
