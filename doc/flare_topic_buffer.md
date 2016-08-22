

# Module flare_topic_buffer #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-backlog_size">backlog_size()</a> ###


<pre><code>
backlog_size() = pos_integer() | infinity
</code></pre>




### <a name="type-broker">broker()</a> ###


<pre><code>
broker() = #broker{node_id = non_neg_integer(), host = binary(), port = pos_integer()}
</code></pre>




### <a name="type-buffer_name">buffer_name()</a> ###


<pre><code>
buffer_name() = atom()
</code></pre>




### <a name="type-client_option">client_option()</a> ###


<pre><code>
client_option() = {ip, <a href="inet.md#type-ip_address">inet:ip_address()</a> | <a href="inet.md#type-hostname">inet:hostname()</a>} | {port, <a href="inet.md#type-port_number">inet:port_number()</a>} | {protocol, <a href="#type-protocol">protocol()</a>} | {reconnect, boolean()} | {reconnect_time_max, <a href="#type-time">time()</a>} | {reconnect_time_min, <a href="#type-time">time()</a>} | {socket_options, [<a href="gen_tcp.md#type-connect_option">gen_tcp:connect_option()</a> | <a href="gen_udp.md#type-option">gen_udp:option()</a>]}
</code></pre>




### <a name="type-client_options">client_options()</a> ###


<pre><code>
client_options() = [<a href="#type-client_option">client_option()</a>]
</code></pre>




### <a name="type-compression">compression()</a> ###


<pre><code>
compression() = 0 | 2
</code></pre>




### <a name="type-compression_name">compression_name()</a> ###


<pre><code>
compression_name() = none | snappy
</code></pre>




### <a name="type-msg">msg()</a> ###


<pre><code>
msg() = binary()
</code></pre>




### <a name="type-partition_id">partition_id()</a> ###


<pre><code>
partition_id() = non_neg_integer()
</code></pre>




### <a name="type-partition_tuple">partition_tuple()</a> ###


<pre><code>
partition_tuple() = {<a href="#type-partition_id">partition_id()</a>, atom(), <a href="#type-broker">broker()</a>}
</code></pre>




### <a name="type-partition_tuples">partition_tuples()</a> ###


<pre><code>
partition_tuples() = [<a href="#type-partition_tuple">partition_tuple()</a>]
</code></pre>




### <a name="type-pool_option">pool_option()</a> ###


<pre><code>
pool_option() = {backlog_size, <a href="#type-backlog_size">backlog_size()</a>} | {pool_size, <a href="#type-pool_size">pool_size()</a>} | {pool_strategy, <a href="#type-pool_strategy">pool_strategy()</a>}
</code></pre>




### <a name="type-pool_options">pool_options()</a> ###


<pre><code>
pool_options() = [<a href="#type-pool_option">pool_option()</a>]
</code></pre>




### <a name="type-pool_size">pool_size()</a> ###


<pre><code>
pool_size() = pos_integer()
</code></pre>




### <a name="type-pool_strategy">pool_strategy()</a> ###


<pre><code>
pool_strategy() = random | round_robin
</code></pre>




### <a name="type-protocol">protocol()</a> ###


<pre><code>
protocol() = shackle_tcp | shackle_udp
</code></pre>




### <a name="type-req_id">req_id()</a> ###


<pre><code>
req_id() = {<a href="erlang.md#type-timestamp">erlang:timestamp()</a>, pid()}
</code></pre>




### <a name="type-request">request()</a> ###


<pre><code>
request() = {<a href="#type-req_id">req_id()</a>, pid() | undefined}
</code></pre>




### <a name="type-requests">requests()</a> ###


<pre><code>
requests() = [<a href="#type-request">request()</a>]
</code></pre>




### <a name="type-state">state()</a> ###


<pre><code>
state() = #state{acks = 1..65535, buffer = list(), buffer_count = non_neg_integer(), buffer_delay = pos_integer(), buffer_size = non_neg_integer(), buffer_size_max = undefined | pos_integer(), buffer_timer_ref = undefined | reference(), compression = <a href="#type-compression">compression()</a>, metadata_delay = pos_integer(), metadata_timer_ref = undefined | reference(), name = atom(), parent = pid(), partitions = undefined | list(), requests = <a href="#type-requests">requests()</a>, topic = <a href="#type-topic_name">topic_name()</a>}
</code></pre>




### <a name="type-time">time()</a> ###


<pre><code>
time() = pos_integer()
</code></pre>




### <a name="type-topic_name">topic_name()</a> ###


<pre><code>
topic_name() = binary()
</code></pre>




### <a name="type-topic_opt">topic_opt()</a> ###


<pre><code>
topic_opt() = {acks, 0..65535} | {buffer_delay, pos_integer()} | {buffer_size, non_neg_integer()} | {compression, <a href="#type-compression_name">compression_name()</a>} | {metadata_delay, pos_integer()} | {pool_size, pos_integer()}
</code></pre>




### <a name="type-topic_opts">topic_opts()</a> ###


<pre><code>
topic_opts() = [<a href="#type-topic_opt">topic_opt()</a>]
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#init-5">init/5</a></td><td></td></tr><tr><td valign="top"><a href="#produce-4">produce/4</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-4">start_link/4</a></td><td></td></tr><tr><td valign="top"><a href="#system_code_change-4">system_code_change/4</a></td><td></td></tr><tr><td valign="top"><a href="#system_continue-3">system_continue/3</a></td><td></td></tr><tr><td valign="top"><a href="#system_get_state-1">system_get_state/1</a></td><td></td></tr><tr><td valign="top"><a href="#system_terminate-4">system_terminate/4</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="init-5"></a>

### init/5 ###

<pre><code>
init(Parent::pid(), Name::<a href="#type-buffer_name">buffer_name()</a>, Topic::<a href="#type-topic_name">topic_name()</a>, Opts::<a href="#type-topic_opts">topic_opts()</a>, Partitions::<a href="#type-partition_tuples">partition_tuples()</a>) -&gt; no_return()
</code></pre>
<br />

<a name="produce-4"></a>

### produce/4 ###

<pre><code>
produce(Messages::[<a href="#type-msg">msg()</a>], Requests::<a href="#type-requests">requests()</a>, Pid::pid(), State::<a href="#type-state">state()</a>) -&gt; ok
</code></pre>
<br />

<a name="start_link-4"></a>

### start_link/4 ###

<pre><code>
start_link(Name::<a href="#type-buffer_name">buffer_name()</a>, Topic::<a href="#type-topic_name">topic_name()</a>, Opts::<a href="#type-topic_opts">topic_opts()</a>, Partitions::<a href="#type-partition_tuples">partition_tuples()</a>) -&gt; {ok, pid()}
</code></pre>
<br />

<a name="system_code_change-4"></a>

### system_code_change/4 ###

<pre><code>
system_code_change(State::<a href="#type-state">state()</a>, Module::module(), OldVsn::undefined | term(), Extra::term()) -&gt; {ok, <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="system_continue-3"></a>

### system_continue/3 ###

<pre><code>
system_continue(Parent::pid(), Debug::[], State::<a href="#type-state">state()</a>) -&gt; ok
</code></pre>
<br />

<a name="system_get_state-1"></a>

### system_get_state/1 ###

<pre><code>
system_get_state(State::<a href="#type-state">state()</a>) -&gt; {ok, <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="system_terminate-4"></a>

### system_terminate/4 ###

<pre><code>
system_terminate(Reason::term(), Parent::pid(), Debug::[], State::<a href="#type-state">state()</a>) -&gt; none()
</code></pre>
<br />

