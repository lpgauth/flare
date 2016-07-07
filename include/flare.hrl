%% protocol
-define(API_VERSION, 0).
-define(CLIENT_ID, "flare").
-define(MAX_REQUEST_ID, 4294967296).
-define(OFFSET, 0).
-define(REQUEST_PRODUCE, 0).
-define(REQUEST_METADATA, 3).

-define(COMPRESSION_NONE, 0).
-define(COMPRESSION_SNAPPY, 2).

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
-type compression_name()   :: none | snappy.
-type compression()        :: ?COMPRESSION_NONE |
                              ?COMPRESSION_SNAPPY.
-type msg()                :: binary().
-type partition()          :: #partition {}.
-type partition_id()       :: non_neg_integer().
-type partition_tuple()    :: {partition_id(), atom(), broker()}.
-type partition_tuples()   :: [partition_tuple()].
-type partition_metadata() :: #partition_metadata {}.
-type topic()              :: #topic {}.
-type topic_name()         :: binary().
-type topic_metadata()     :: #topic_metadata {}.
-type topic_opt()          :: {acks, 0..65535} |
                              {buffer_delay, pos_integer()} |
                              {buffer_size, non_neg_integer()} |
                              {compression, compression_name()} |
                              {pool_size, pos_integer()}.
-type topic_opts()         :: [topic_opt()].
