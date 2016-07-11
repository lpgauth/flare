-module(flare_response).
-include("flare_internal.hrl").

-export([
   error_code/1
]).

%% public
-spec error_code(0..65535) ->
    ok | {error, atom()}.

error_code(?ERROR_NONE) ->
    ok;
error_code(?ERROR_OFFSET_OUT_OF_RANGE) ->
    {error, offset_out_of_range};
error_code(?ERROR_CORRUPT_MESSAGE) ->
    {error, corrupt_message};
error_code(?ERROR_UNKNOWN_TOPIC_OR_PARTITION) ->
    {error, unknown_topic_or_partition};
error_code(?ERROR_INVALID_FETCH_SIZE) ->
    {error, invalid_fetch_size};
error_code(?ERROR_LEADER_NOT_AVAILABLE) ->
    {error, leader_no_available};
error_code(?ERROR_NOT_LEADER_FOR_PARTITION) ->
    {error, not_leader_for_partition};
error_code(?ERROR_REQUEST_TIMED_OUT) ->
    {error, request_timed_out};
error_code(?ERROR_BROKER_NOT_AVAILABLE) ->
    {error, broker_not_available};
error_code(?ERROR_REPLICA_NOT_AVAILABLE) ->
    {error, replica_not_available};
error_code(?ERROR_MESSAGE_TOO_LARGE) ->
    {error, message_too_large};
error_code(?ERROR_STALE_CONTROLLER_EPOCH) ->
    {error, stale_controller_epoch};
error_code(?ERROR_OFFSET_METADATA_TOO_LARGE) ->
    {error, offset_metadata_too_large};
error_code(?ERROR_NETWORK_EXCEPTION) ->
    {error, network_exception};
error_code(?ERROR_GROUP_LOAD_IN_PROGRESS) ->
    {error, group_load_in_progress};
error_code(?ERROR_GROUP_COORDINATOR_NOT_AVAILABLE) ->
    {error, group_coordinator_not_available};
error_code(?ERROR_NOT_COORDINATOR_FOR_GROUP) ->
    {error, not_coordinator_for_group};
error_code(?ERROR_INVALID_TOPIC_EXCEPTION) ->
    {error, invalid_topic_exception};
error_code(?ERROR_RECORD_LIST_TOO_LARGE) ->
    {error, record_list_too_large};
error_code(?ERROR_NOT_ENOUGH_REPLICAS) ->
    {error, not_enough_replicas};
error_code(?ERROR_NOT_ENOUGH_REPLICAS_AFTER_APPEND) ->
    {error, not_enough_replicas_after_append};
error_code(?ERROR_INVALID_REQUIRED_ACKS) ->
    {error, invalid_required_acks};
error_code(?ERROR_ILLEGAL_GENERATION) ->
    {error, illegal_generation};
error_code(?ERROR_INCONSISTENT_GROUP_PROTOCOL) ->
    {error, inconsistent_group_protocol};
error_code(?ERROR_INVALID_GROUP_ID) ->
    {error, invalid_group_id};
error_code(?ERROR_UNKNOWN_MEMBER_ID) ->
    {error, unknown_member_id};
error_code(?ERROR_INVALID_SESSION_TIMEOUT) ->
    {error, invalid_session_timeout};
error_code(?ERROR_REBALANCE_IN_PROGRESS) ->
    {error, rebalance_in_progress};
error_code(?ERROR_INVALID_COMMIT_OFFSET_SIZE) ->
    {error, invalid_commit_offset_size};
error_code(?ERROR_TOPIC_AUTHORIZATION_FAILED) ->
    {error, topic_authorization_failed};
error_code(?ERROR_GROUP_AUTHORIZATION_FAILED) ->
    {error, group_authorization_failed};
error_code(?ERROR_CLUSTER_AUTHORIZATION_FAILED) ->
    {error, cluster_authorization_failed};
error_code(?ERROR_INVALID_TIMESTAMP) ->
    {error, invalid_timestamp};
error_code(?ERROR_UNSUPPORTED_SASL_MECHANISM) ->
    {error, unsupported_sasl_mechanism};
error_code(?ERROR_ILLEGAL_SASL_STATE) ->
    {error, illegal_sasl_state};
error_code(?ERROR_UNSUPPORTED_VERSION) ->
    {error, unsupported_version};
error_code(?ERROR_UNKNOWN) ->
    {error, unknown}.
