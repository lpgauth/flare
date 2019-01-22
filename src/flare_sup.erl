-module(flare_sup).
-include("flare_internal.hrl").

-export([
    start_link/0
]).

-behaviour(supervisor).
-export([
    init/1
]).

%% public
-spec start_link() ->
    {ok, pid()}.

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% supervisor callbacks
-spec init([]) ->
    {ok, {{one_for_one, 5, 10}, []}}.

init([]) ->
    flare_api_versions:init(),
    flare_queue:init(),
    flare_topic:init(),

    {ok, {{one_for_one, 5, 10}, []}}.
