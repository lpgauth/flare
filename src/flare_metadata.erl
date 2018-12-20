-module(flare_metadata).
-include("flare_internal.hrl").

-export([
    partitions/1
]).

%% public
-spec partitions(topic_name()) ->
    {ok, partition_tuples()} | {error, term()}.

partitions(Topic) ->
    case topic(Topic) of
        {ok, {_Brokers, [#topic_metadata {partion_metadata = []}]}} ->
            {error, no_metadata};
        {ok, {Brokers, [#topic_metadata {partion_metadata = Metadata}]}} ->
            {ok, partition_tuples(Metadata, Brokers)};
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

partition_tuples([], _Brokers) ->
    [];
partition_tuples([#partition_metadata {
        partition_id = PartitionId,
        leader = Id
    } | T], Brokers) ->

    case broker(Id, Brokers) of
        undefined ->
            partition_tuples(T, Brokers);
        Broker ->
            [{PartitionId, name(Id), Broker} | partition_tuples(T, Brokers)]
    end.

topic(Topic) ->
    topic(?GET_ENV(broker_bootstrap_servers,
        ?DEFAULT_BROKER_BOOTSTRAP_SERVERS), Topic).

topic([], _Topic) ->
    {error, no_metadata};
topic([{Ip, Port} | T], Topic) ->
    Request = flare_protocol:encode_metadata([Topic]),
    Data = flare_protocol:encode_request(?REQUEST_METADATA,
        ?METADATA_API_VERSION, 0, ?CLIENT_ID, Request),
    case flare_utils:send_recv(Ip, Port, Data) of
        {ok, Data2} ->
            {0, Brokers, TopicMetadata} =
                flare_protocol:decode_metadata(Data2),
            {ok, {Brokers, TopicMetadata}};
        {error, _Reason} ->
            topic(T, Topic)
    end.
