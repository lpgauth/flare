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

produce(Topic, Message) ->
    flare_topic:produce(Topic, Message).
