-module(flare_protocol).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    decode_metadata/1,
    decode_produce/1,
    encode_produce/7,
    encode_metadata/3,
    encode_message_set/1
]).

%% public
-spec decode_metadata(binary()) ->
    {non_neg_integer(), [broker()], [topic_metadata()]}.

decode_metadata(<<CorrelationId:32, Rest/binary>>) ->
    {Brokers, Rest2} = decode_broker_array(Rest),
    {TopicMetadata, <<>>} = decode_topic_metadata_array(Rest2),
    {CorrelationId, Brokers, TopicMetadata}.

-spec decode_produce(binary()) ->
    term().

decode_produce(<<CorrelationId:32, Length:32, Rest/binary>>) ->
    {TopicArray, <<>>} = decode_topic_array(Length, [], Rest),
    {CorrelationId, TopicArray}.

-spec encode_produce(integer(), iolist(), topic_name(), non_neg_integer(),
    msg(), integer(), compression()) -> iolist().

encode_produce(CorrelationId, ClientId, Topic, Partition, Messages, Acks,
        Compression) ->

    MessageSet = encode_message_set(Messages, Compression),
    Partition2 = encode_partion(Partition, MessageSet),
    Topic2 = [[encode_string(Topic), encode_array([Partition2])]],
    Request = [<<Acks:16, (?TIMEOUT):32>>, encode_array(Topic2)],
    encode_request(?REQUEST_PRODUCE, CorrelationId, ClientId, Request).

-spec encode_metadata(integer(), iolist(), [iolist()]) ->
    iolist().

encode_metadata(CorrelationId, ClientId, Topics) ->
    Request = encode_array([encode_string(Topic) || Topic <- Topics]),
    encode_request(?REQUEST_METADATA, CorrelationId, ClientId, Request).

-spec encode_message_set(binary() | [binary()]) ->
    iolist().

encode_message_set(Messages) ->
    encode_message_set(Messages, 0).

-spec encode_message_set(binary() | [binary()], compression()) ->
    iolist().

encode_message_set([], _Compression) ->
    [];
encode_message_set(Message, Compression) when is_binary(Message) ->
    Message2 = encode_message(Message, Compression),
    [<<?OFFSET:64, (iolist_size(Message2)):32>>, Message2];
encode_message_set([Message | T], Compression) ->
    Message2 = encode_message(Message, Compression),
    [[<<?OFFSET:64, (iolist_size(Message2)):32>>, Message2],
        encode_message_set(T, Compression)].

%% private
decode_broker(<<NodeId:32, Rest/binary>>) ->
    {Host, Rest2} = decode_string(Rest),
    {Port, Rest3} = decode_int(Rest2),
    {#broker {
        node_id = NodeId,
        host = Host,
        port = Port
    }, Rest3}.

decode_broker_array(<<Length:32, Rest/binary>>) ->
    decode_broker_array(Length, [], Rest).

decode_broker_array(0, Acc, Rest) ->
    {Acc, Rest};
decode_broker_array(Length, Acc, Rest) ->
    {Broker, Rest2} = decode_broker(Rest),
    decode_broker_array(Length - 1, [Broker | Acc], Rest2).

decode_int(<<Int:32, Rest/binary>>) ->
    {Int, Rest}.

decode_int_array(<<Length:32, Rest/binary>>) ->
    decode_int_array(Length, [], Rest).

decode_int_array(0, Acc, Rest) ->
    {Acc, Rest};
decode_int_array(Length, Acc, Rest) ->
    {Int, Rest2} = decode_int(Rest),
    decode_int_array(Length - 1, [Int | Acc], Rest2).

decode_partition(<<Partition:32, ErrorCode:16, Offset:64, Rest/binary>>) ->
    {#partition {
        partition = Partition,
        error_code = ErrorCode,
        offset = Offset
    }, Rest}.

decode_partion_array(0, Acc, Rest) ->
    {Acc, Rest};
decode_partion_array(Length, Acc, Rest) ->
    {Partition, Rest2} = decode_partition(Rest),
    decode_partion_array(Length - 1, [Partition | Acc], Rest2).

decode_partition_metadata(0, Acc, Rest) ->
    {Acc, Rest};
decode_partition_metadata(Length, Acc, Rest) ->
    {PartitionMetadata, Rest2} = decode_partition_metadata(Rest),
    decode_partition_metadata(Length - 1, [PartitionMetadata | Acc], Rest2).

decode_partition_metadata(<<ErrorCode:16, Id:32, Leader:32, Rest/binary>>) ->
    {Replicas, Rest2} = decode_int_array(Rest),
    {Isr, Rest3} = decode_int_array(Rest2),

    {#partition_metadata {
        partion_error_code = ErrorCode,
        partition_id = Id,
        leader = Leader,
        replicas = Replicas,
        isr = Isr
    }, Rest3}.

decode_string(<<-1:16/signed>>) ->
    undefined;
decode_string(<<Pos:16, Rest/binary>>) ->
    <<Value:Pos/binary, Rest2/binary>> = Rest,
    {Value, Rest2}.

decode_topic(Rest) ->
    {Topic, <<Length:32, Rest2/binary>>} = decode_string(Rest),
    {Partions, Rest3} = decode_partion_array(Length, [], Rest2),
    {#topic {
        topic_name = Topic,
        partions = Partions
    }, Rest3}.

decode_topic_array(0, Acc, Rest) ->
    {Acc, Rest};
decode_topic_array(Length, Acc, Rest) ->
    {Topic, Rest2} = decode_topic(Rest),
    decode_topic_array(Length - 1, [Topic | Acc], Rest2).

decode_topic_metadata(<<ErrorCode:16, Rest/binary>>) ->
    {TopicName, <<Length:32, Rest3/binary>>} = decode_string(Rest),
    {PartitionMetadata, Rest4} = decode_partition_metadata(Length, [], Rest3),
    {#topic_metadata {
        topic_error_code = ErrorCode,
        topic_name = TopicName,
        partion_metadata = PartitionMetadata
    }, Rest4}.

decode_topic_metadata_array(<<Length:32, Rest/binary>>) ->
    decode_topic_metadata_array(Length, [], Rest).

decode_topic_metadata_array(0, Acc, Rest) ->
    {Acc, Rest};
decode_topic_metadata_array(Length, Acc, Rest) ->
    {TopicMetadata, Rest2} = decode_topic_metadata(Rest),
    decode_topic_metadata_array(Length - 1, [TopicMetadata | Acc], Rest2).

encode_array(Array) ->
    [<<(length(Array)):32>>, Array].

encode_bytes(undefined) ->
    <<-1:32/signed>>;
encode_bytes(Data) ->
    [<<(iolist_size(Data)):32>>, Data].

encode_message(Message, Compresion) ->
    Message2 = [<<?API_VERSION:8, Compresion:8>>, encode_bytes(undefined),
        encode_bytes(Message)],
    [<<(erlang:crc32(Message2)):32>>, Message2].

encode_partion(Partition, MessageSet) ->
    [<<Partition:32, (iolist_size(MessageSet)):32>>, MessageSet].

encode_request(ApiKey, CorrelationId, ClientId, Request) ->
    [<<ApiKey:16, ?API_VERSION:16, CorrelationId:32>>,
        encode_string(ClientId), Request].

encode_string(undefined) ->
    <<-1:16/signed>>;
encode_string(Data) ->
    [<<(iolist_size(Data)):16>>, Data].
