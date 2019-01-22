-module(flare_metadata).
-include("flare_internal.hrl").

-export([
    partitions/1
]).

%% public
-spec partitions(topic()) ->
    {ok, [partition_tuple()]} | {error, term()}.

partitions(Topic) ->
    case topic(Topic) of
        {ok, {Brokers, TopicMetadata}} ->
            {ok, partition_tuples(Brokers, TopicMetadata)};
        {error, Reason} ->
            {error, Reason}
    end.

%% private
broker(_Id, []) ->
    undefined;
broker(Id, [#{node_id := Id} = Broker | _]) ->
    Broker;
broker(Id, [#{} | T]) ->
    broker(Id, T).

name(Id) ->
    list_to_atom("flare_broker_" ++ integer_to_list(Id)).

partition_tuples(_Brokers, []) ->
    [];
partition_tuples(Brokers, [#{
        leader := Leader,
        partition := Partition
    } | T]) ->

    case broker(Leader, Brokers) of
        undefined ->
            partition_tuples(Brokers, T);
        Broker ->
            [{Partition, name(Leader), Broker} |
                partition_tuples(Brokers, T)]
    end.

topic(Topic) ->
    topic(?GET_ENV(broker_bootstrap_servers,
        ?DEFAULT_BROKER_BOOTSTRAP_SERVERS), Topic).

topic([], _Topic) ->
    {error, bootstrap_failed};
topic([{Ip, Port} | T], Topic) ->
    Req = flare_kpro:encode_metadata(Topic),
    Data = flare_kpro:encode_request(0, Req),
    case flare_utils:send_recv(Ip, Port, Data) of
        {ok, <<0:32, Bin/binary>>} ->
            flare_kpro:decode_metadata(Bin);
        {error, _Reason} ->
            topic(T, Topic)
    end.
