-module(flare_kpro).
-include("flare_internal.hrl").
-include_lib("kafka_protocol/include/kpro.hrl").

-compile(inline).
-compile({inline_size, 512}).

-export([
    decode_api_versions/1,
    decode_produce/1,
    decode_metadata/1,
    encode_api_versions/0,
    encode_metadata/1,
    encode_produce/4,
    encode_request/2
]).

%% public
-spec decode_api_versions(binary()) ->
    {ok, [map()]} | {error, atom()}.

decode_api_versions(Bin) ->
    #kpro_rsp {
        msg = Msg
    } = kpro_rsp_lib:decode(api_versions, ?API_VERSIONS_VSN, Bin, false),
    ApiVersions = maps:get(api_versions, Msg),
    ErrorCode = maps:get(error_code, Msg),
    ok_or_error_tuple(ErrorCode, ApiVersions).

-spec decode_produce(binary()) ->
    ok | {error, atom()}.

decode_produce(Bin) ->
    {ok, Vsn} = flare_api_versions:produce(),
    #kpro_rsp {
        msg = Msg
    } = kpro_rsp_lib:decode(produce, Vsn, Bin, false),
    [Response | _] = maps:get(responses, Msg),
    [PartitionResponse | _] = maps:get(partition_responses, Response),
    ErrorCode = maps:get(error_code, PartitionResponse),
    ok_or_error_tuple(ErrorCode).

-spec decode_metadata(binary()) ->
    {ok, {[map()], [map()]}} | {error, atom()}.

decode_metadata(Bin) ->
    #kpro_rsp {
        msg = Msg
    } = kpro_rsp_lib:decode(metadata, ?METADATA_VSN, Bin, false),
    Brokers = maps:get(brokers, Msg),
    [TopicMetadata | _] = maps:get(topic_metadata, Msg),
    ErrorCode = maps:get(error_code, TopicMetadata),
    PartitionMetadata = maps:get(partition_metadata, TopicMetadata),
    ok_or_error_tuple(ErrorCode, {Brokers, PartitionMetadata}).

-spec encode_api_versions() ->
    kpro:req().

encode_api_versions() ->
    kpro_req_lib:make(api_versions, ?API_VERSIONS_VSN, []).

-spec encode_metadata(topic()) ->
    kpro:req().

encode_metadata(Topic) ->
    kpro_req_lib:metadata(?METADATA_VSN, [Topic]).

-spec encode_produce(topic(), partition_id(), [msg()], produce_opts()) ->
    kpro:req().

encode_produce(Topic, Partition, Batch, Opts) ->
    {ok, Vsn} = flare_api_versions:produce(),
    kpro_req_lib:produce(Vsn, Topic, Partition, Batch, Opts).

-spec encode_request(non_neg_integer(),  kpro:req()) ->
    iolist().

encode_request(CorrelationId, Request) ->
    kpro:encode_request(?CLIENT_ID, CorrelationId, Request).

%% private
ok_or_error_tuple(no_error) ->
    ok;
ok_or_error_tuple(ErrorCode) ->
    {error, ErrorCode}.

ok_or_error_tuple(no_error, Response) ->
    {ok, Response};
ok_or_error_tuple(ErrorCode, _Response) ->
    {error, ErrorCode}.
