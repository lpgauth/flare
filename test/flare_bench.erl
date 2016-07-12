-module(flare_bench).

-export([
    run/0
]).

-define(N, 1000).
-define(P, 20).

%% public
-spec run() -> ok.

run() ->
    Filenames = filelib:wildcard("_build/default/lib/*/ebin/*.beam"),
    Rootnames = [filename:rootname(Filename, ".beam") ||
        Filename <- Filenames],
    lists:foreach(fun code:load_abs/1, Rootnames),

    flare_app:start(),
    Topic = <<"test">>,
    ok = flare_topic:start(Topic),
    timer:sleep(1000),

    Timing = timing:function(fun () ->
        flare:produce(Topic, <<"event1">>)
    end, ?N, ?P),

    io:format("~p~n", [Timing]),

    flare_app:stop(),
    ok.
