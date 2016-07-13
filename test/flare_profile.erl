-module(flare_profile).


-export([
    fprofx/0
]).

-define(N, 1000).
-define(P, 20).

%% public
-spec fprofx() -> ok.

fprofx() ->
    Filenames = filelib:wildcard("_build/default/lib/*/ebin/*.beam"),
    Rootnames = [filename:rootname(Filename, ".beam") ||
        Filename <- Filenames],
    lists:foreach(fun code:load_abs/1, Rootnames),

    fprofx:start(),
    {ok, Tracer} = fprofx:profile(start),
    fprofx:trace([start, {procs, new}, {tracer, Tracer}]),

    flare_app:start(),
    Topic = <<"test">>,
    ok = flare_topic:start(Topic),

    Self = self(),
    [spawn(fun () ->
        [flare:async_produce(Topic, <<"event1">>) || _ <- lists:seq(1, ?N)],
        Self ! exit
    end) || _ <- lists:seq(1, ?P)],
    wait(),

    fprofx:trace(stop),
    fprofx:analyse([totals, {dest, ""}]),
    fprofx:stop(),

    flare_app:stop(),
    ok.

%% private
wait() ->
    wait(?P).

wait(0) ->
    ok;
wait(X) ->
    receive
        exit ->
            wait(X - 1)
    end.
