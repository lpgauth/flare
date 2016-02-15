-module(flare_metadata).
-include("flare_internal.hrl").

-export([
    partitions/1
]).

%% public
-spec partitions(topic_name()) ->
    {ok, [{partition_id(), atom(), broker()}]} | {error, term()}.

partitions(Topic) ->
    case topic(Topic) of
        {ok, {_Brokers, [#topic_metadata {partion_metadata = []}]}} ->
            [];
        {ok, {Brokers, [#topic_metadata {
                partion_metadata = PartitionMetadata
            }]}} ->

            {ok, [{PartitionId, name(Id), broker(Id, Brokers)} ||
                #partition_metadata {
                    partition_id = PartitionId,
                    leader = Id
                } <- PartitionMetadata]};
        {error, Reason} ->
            {error, Reason}
    end.

%% private
broker(Id, Brokers) ->
    case lists:keyfind(Id, 2, Brokers) of
        false ->
            undefined;
        #broker {} = Broker ->
            Broker
    end.

name(Id) ->
    list_to_atom("flare_broker_" ++ integer_to_list(Id)).

topic(Topic) ->
    topic(?GET_ENV(bootstrap_brokers, ?DEFAULT_BOOTSTRAP_BROKERS), Topic).

topic([], _Topic) ->
    {error, no_metadata};
topic([{Ip, Port} | T], Topic) ->
    Data = flare_protocol:encode_metadata(0, ?CLIENT_ID, [Topic]),
    case flare_utils:send_recv(Ip, Port, Data) of
        {ok, Data2} ->
            {0, Brokers, TopicMetadata} =
                flare_protocol:decode_metadata(Data2),
            {ok, {Brokers, TopicMetadata}};
        {error, _Reason} ->
            topic(T, Topic)
    end.
