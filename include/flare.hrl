%% protocol
-define(API_VERSION, 0).
-define(CLIENT_ID, "flare").
-define(MAX_REQUEST_ID, 4294967296).
-define(OFFSET, 0).
-define(REQUEST_PRODUCE, 0).
-define(REQUEST_METADATA, 3).

-define(COMPRESSION_NONE, 0).
-define(COMPRESSION_SNAPPY, 2).

-define(ERROR_NONE, 0).
-define(ERROR_OFFSET_OUT_OF_RANGE, 1).
-define(ERROR_CORRUPT_MESSAGE, 2).
-define(ERROR_UNKNOWN_TOPIC_OR_PARTITION, 3).
-define(ERROR_INVALID_FETCH_SIZE, 4).
-define(ERROR_LEADER_NOT_AVAILABLE, 5).
-define(ERROR_NOT_LEADER_FOR_PARTITION, 6).
-define(ERROR_REQUEST_TIMED_OUT, 7).
-define(ERROR_BROKER_NOT_AVAILABLE, 8).
-define(ERROR_REPLICA_NOT_AVAILABLE, 9).
-define(ERROR_MESSAGE_TOO_LARGE, 10).
-define(ERROR_STALE_CONTROLLER_EPOCH, 11).
-define(ERROR_OFFSET_METADATA_TOO_LARGE, 12).
-define(ERROR_NETWORK_EXCEPTION, 13).
-define(ERROR_GROUP_LOAD_IN_PROGRESS, 14).
-define(ERROR_GROUP_COORDINATOR_NOT_AVAILABLE, 15).
-define(ERROR_NOT_COORDINATOR_FOR_GROUP, 16).
-define(ERROR_INVALID_TOPIC_EXCEPTION, 17).
-define(ERROR_RECORD_LIST_TOO_LARGE, 18).
-define(ERROR_NOT_ENOUGH_REPLICAS, 19).
-define(ERROR_NOT_ENOUGH_REPLICAS_AFTER_APPEND, 20).
-define(ERROR_INVALID_REQUIRED_ACKS, 21).
-define(ERROR_ILLEGAL_GENERATION, 22).
-define(ERROR_INCONSISTENT_GROUP_PROTOCOL, 23).
-define(ERROR_INVALID_GROUP_ID, 24).
-define(ERROR_UNKNOWN_MEMBER_ID, 25).
-define(ERROR_INVALID_SESSION_TIMEOUT, 26).
-define(ERROR_REBALANCE_IN_PROGRESS, 27).
-define(ERROR_INVALID_COMMIT_OFFSET_SIZE, 28).
-define(ERROR_TOPIC_AUTHORIZATION_FAILED, 29).
-define(ERROR_GROUP_AUTHORIZATION_FAILED, 30).
-define(ERROR_CLUSTER_AUTHORIZATION_FAILED, 31).
-define(ERROR_INVALID_TIMESTAMP, 32).
-define(ERROR_UNSUPPORTED_SASL_MECHANISM, 33).
-define(ERROR_ILLEGAL_SASL_STATE, 34).
-define(ERROR_UNSUPPORTED_VERSION, 35).
-define(ERROR_UNKNOWN, 65535).

%% record
-record(broker, {
    node_id :: non_neg_integer(),
    host    :: binary(),
    port    :: pos_integer()
}).

-record(partition, {
    partition  :: non_neg_integer(),
    error_code :: non_neg_integer(),
    offset     :: non_neg_integer()
}).

-record(partition_metadata, {
    partion_error_code :: non_neg_integer(),
    partition_id       :: non_neg_integer(),
    leader             :: non_neg_integer(),
    replicas           :: [non_neg_integer()],
    isr                :: [non_neg_integer()]
}).

-record(topic, {
    topic_name :: topic_name(),
    partions   :: [partition()]
}).

-record(topic_metadata, {
    topic_error_code :: non_neg_integer(),
    topic_name       :: binary(),
    partion_metadata :: [partition_metadata()]
}).

%% types
-type broker()             :: #broker {}.
-type buffer_name()        :: atom().
-type compression_name()   :: none | snappy.
-type compression()        :: ?COMPRESSION_NONE |
                              ?COMPRESSION_SNAPPY.
-type ext_req_id()         :: shackle:request_id().
-type msg()                :: binary().
-type partition()          :: #partition {}.
-type partition_id()       :: non_neg_integer().
-type partition_tuple()    :: {partition_id(), atom(), broker()}.
-type partition_tuples()   :: [partition_tuple()].
-type partition_metadata() :: #partition_metadata {}.
-type request()            :: {req_id(), pid() | undefined}.
-type requests()           :: [request()].
-type req_id()             :: {erlang:timestamp(), pid()}.
-type topic()              :: #topic {}.
-type topic_name()         :: binary().
-type topic_metadata()     :: #topic_metadata {}.
-type topic_opt()          :: {acks, 0..65535} |
                              {buffer_delay, pos_integer()} |
                              {buffer_size, non_neg_integer()} |
                              {compression, compression_name()} |
                              {metadata_delay, pos_integer()} |
                              {pool_size, pos_integer()}.
-type topic_opts()         :: [topic_opt()].
