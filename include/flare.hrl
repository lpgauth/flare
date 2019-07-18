%% protocol
-define(CLIENT_ID, <<"flare">>).
-define(MAX_REQUEST_ID, 4294967296).

% vsn
-define(API_VERSIONS_VSN, 0).
-define(KAFKA_0_9_PRODUCE_VSN, 0).
-define(METADATA_VSN, 0).
-define(PRODUCE_VSN, 5).
-define(PRODUCE_VSN_RANGE, {0, ?PRODUCE_VSN}).

%% types
-type acks()             :: -1..1 | all_isr | none | leader_only.
-type broker()           :: map().
-type buffer_name()      :: atom().
-type buffer_size()      :: non_neg_integer().
-type compression()      :: no_compression | gzip | snappy.
-type ext_req_id()       :: shackle:request_id().
-type headers()          :: [{binary(), binary()}].
-type key()              :: binary() | undefined.
-type msg()              :: #{headers => headers(),
                              ts => timestamp(),
                              key => key(),
                              value => value()}.
-type partition_id()     :: non_neg_integer().
-type partition_tuple()  :: {partition_id(), atom(), broker()}.
-type produce_opts()     :: #{compression => compression(),
                              required_acks => acks()}.
-type request()          :: {req_id(), pid() | undefined}.
-type req_id()           :: {erlang:timestamp(), pid()}.
-type timestamp()        :: non_neg_integer().
-type topic()            :: binary().
-type topic_opt()        :: {acks, acks()} |
                            {buffer_delay, pos_integer()} |
                            {buffer_size, buffer_size()} |
                            {compression, compression()} |
                            {metadata_delay, pos_integer()} |
                            {pool_size, pos_integer()}.
-type value()            :: binary() | undefined.
-type vsn()              :: non_neg_integer().
