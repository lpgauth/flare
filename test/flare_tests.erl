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
    [flare:produce(Topic, <<"event1">>) || _ <- lists:seq(1, 10000)],
    ok = flare_topic:stop(Topic).

% utils
cleanup() ->
    flare_app:stop().

setup() ->
    error_logger:tty(false),
    flare_app:start().
