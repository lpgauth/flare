-module(flare).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    produce/2
]).

%% public
-spec produce(topic_name(), msg()) ->
    ok | {error, atom()}.

produce(Topic, Msg) ->
    flare_topic:produce(Topic, Msg).
