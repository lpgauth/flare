-module(flare_protocol).
-include("flare_internal.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    decode_metadata/1,
    decode_produce/1,
    encode_produce/6,
    encode_metadata/1,
    encode_request/5
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
    {TopicArray, <<_ThrottleTime:32>>} = decode_topic_array(Length, [], Rest),
    {CorrelationId, TopicArray}.

-spec encode_produce(produce_api_version(), topic_name(), non_neg_integer(), msg() | [msg()],
    integer(), compression()) -> iolist().

encode_produce(ProduceApi, Topic, Partition, Messages, Acks, Compression) when
        ProduceApi =:= ?PRODUCE_API_0; ProduceApi =:= ?PRODUCE_API_2->

    MsgApiVersion = message_api_version(ProduceApi),
    Messages2 = case Compression of
        ?COMPRESSION_NONE ->
            Messages;
        ?COMPRESSION_SNAPPY ->
            MessagesSet = encode_message_set(Messages, ?COMPRESSION_NONE, MsgApiVersion),
            Timestamp = flare_utils:timestamp(),
            [{flare_utils:compress(Compression, MessagesSet), Timestamp}]
    end,

    MessageSet2 = encode_message_set(Messages2, Compression, MsgApiVersion),
    Partition2 = [<<Partition:32, (iolist_size(MessageSet2)):32>>, MessageSet2],
    Topic2 = [[encode_string(Topic), encode_array([Partition2])]],
    [<<Acks:16, (?TIMEOUT):32>>, encode_array(Topic2)];
encode_produce(?PRODUCE_API_3, Topic, Partition, Messages, Acks, Compression) ->
    RecordBatch = encode_record_batch(Messages, Compression),
    Partition2 = [<<Partition:32, (iolist_size(RecordBatch)):32>>, RecordBatch],
    Topic2 = [[encode_string(Topic), encode_array([Partition2])]],
    TransactionalId = encode_string(undefined),
    [TransactionalId, <<Acks:16, (?TIMEOUT):32>>, encode_array(Topic2)].

-spec encode_metadata([iolist()]) ->
    iolist().

encode_metadata(Topics) ->
    encode_array([encode_string(Topic) || Topic <- Topics]).

-spec encode_request(integer(), integer(), integer(), iolist(), iolist()) ->
    iolist().

encode_request(ApiKey, ApiVersion, CorrelationId, ClientId, Request) ->
    [<<ApiKey:16, ApiVersion:16, CorrelationId:32>>,
        encode_string(ClientId), Request].

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

decode_partition(<<Partition:32, ErrorCode:16, Offset:64, _LogAppendTime:64,
        Rest/binary>>) ->

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

encode_attributes(?COMPRESSION_NONE) ->
    <<0, 0>>;
encode_attributes(?COMPRESSION_SNAPPY) ->
    <<0, 2>>.

encode_bytes(undefined) ->
    <<-1:32/signed>>;
encode_bytes(Data) ->
    [<<(iolist_size(Data)):32>>, Data].

encode_bytes_v2(undefined) ->
    encode_varint(-1);
encode_bytes_v2(Data) ->
    [encode_varint(iolist_size(Data)), Data].

encode_message({Message, _}, Compresion, ?MESSAGE_API_0) ->
    Message2 = [<<0:8, Compresion:8>>,
        encode_bytes(undefined), encode_bytes(Message)],
    [<<(erlang:crc32(Message2)):32>>, Message2];
encode_message({Message, Timestamp}, Compresion, ?MESSAGE_API_1) ->
    Message2 = [<<1:8, Compresion:8, Timestamp:64>>,
        encode_bytes(undefined), encode_bytes(Message)],
    [<<(erlang:crc32(Message2)):32>>, Message2].

encode_message_set([], _Compression, _MsgApiVersion) ->
    [];
encode_message_set([Message | T], Compression, MsgApiVersion) ->
    Message2 = encode_message(Message, Compression, MsgApiVersion),
    [[<<?OFFSET:64, (iolist_size(Message2)):32>>, Message2],
        encode_message_set(T, Compression, MsgApiVersion)].

encode_record({Message, _Timestamp}) ->
    Attributes = <<0:8>>,
    TimestampDelta = <<0>>,
    OffsetDelta = <<0>>,
    Key = encode_bytes_v2(undefined),
    Value = encode_bytes_v2(Message),
    Headers = encode_varint(0), % empty array

    Body = [
        Attributes,
        TimestampDelta,
        OffsetDelta,
        Key,
        Value,
        Headers
    ],

    [encode_varint(iolist_size(Body)), Body].

encode_records(Messages) ->
    [encode_record(Message) || Message <- Messages].

encode_record_batch([{_, Timestamp} | T] = Messages, Compression) ->
    Attributes = encode_attributes(Compression),
    {MaxTimestamp, Count} = max_timestamp(T, Timestamp, 1),
    LastOffsetDelta = <<(Count - 1):32/unsigned-integer>>,
    FirstTimestamp = <<Timestamp:64/unsigned-integer>>,
    MaxTimestamp2 = <<MaxTimestamp:64/unsigned-integer>>,
    ProducerId = <<-1:64/unsigned-integer>>,
    ProducerEpoch = <<-1:16/unsigned-integer>>,
    BaseSequence = <<-1:32/unsigned-integer>>,
    Records = encode_records(Messages),
    Records2 = flare_utils:compress(Compression, Records),

    Body = [
        Attributes,
        LastOffsetDelta,
        FirstTimestamp,
        MaxTimestamp2,
        ProducerId,
        ProducerEpoch,
        BaseSequence,
        <<(length(Messages)):32>>,
        Records2
    ],

    PartitionLeaderEpoch = <<-1:32/unsigned-integer>>,
    Magic = <<2:8/unsigned-integer>>,
    CRC = <<(crc32cer:nif(Body)):32/unsigned-integer>>,

    Body2 = [
        PartitionLeaderEpoch,
        Magic,
        CRC,
        Body
    ],

    BaseOffset = <<0:64/unsigned-integer>>,
    BatchLength = <<(iolist_size(Body2)):32/unsigned-integer>>,

    [
        BaseOffset,
        BatchLength,
        Body2
    ].

encode_string(undefined) ->
    <<-1:16/signed>>;
encode_string(Data) when is_binary(Data) ->
    [<<(size(Data)):16>>, Data];
encode_string(Data) ->
    [<<(length(Data)):16>>, Data].

encode_varint(Int) ->
    I = (Int bsl 1) bxor (Int bsr 63),
    H = I bsr 7,
    L = I band 127,
    case H =:= 0 of
        true  ->
            [L];
        false ->
            [128 + L | encode_varint(H)]
    end.

max_timestamp([], Timestamp, Count) ->
    {Timestamp, Count};
max_timestamp([{T, Timestamp2} | T], Timestamp, Count)
    when Timestamp2 > Timestamp ->

    max_timestamp(T, Timestamp2, Count + 1);
max_timestamp([_ | T], Timestamp, Count)  ->
    max_timestamp(T, Timestamp, Count + 1).

message_api_version(?PRODUCE_API_0) ->
    ?MESSAGE_API_0;
message_api_version(?PRODUCE_API_2) ->
    ?MESSAGE_API_1;
message_api_version(?PRODUCE_API_3) ->
    ?MESSAGE_API_2.
