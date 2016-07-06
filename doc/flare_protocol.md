

# Module flare_protocol #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-broker">broker()</a> ###


<pre><code>
broker() = #broker{node_id = non_neg_integer(), host = binary(), port = pos_integer()}
</code></pre>




### <a name="type-compression">compression()</a> ###


<pre><code>
compression() = 0 | 2
</code></pre>




### <a name="type-msg">msg()</a> ###


<pre><code>
msg() = binary()
</code></pre>




### <a name="type-partition_metadata">partition_metadata()</a> ###


<pre><code>
partition_metadata() = #partition_metadata{partion_error_code = non_neg_integer(), partition_id = non_neg_integer(), leader = non_neg_integer(), replicas = [non_neg_integer()], isr = [non_neg_integer()]}
</code></pre>




### <a name="type-topic_metadata">topic_metadata()</a> ###


<pre><code>
topic_metadata() = #topic_metadata{topic_error_code = non_neg_integer(), topic_name = binary(), partion_metadata = [<a href="#type-partition_metadata">partition_metadata()</a>]}
</code></pre>




### <a name="type-topic_name">topic_name()</a> ###


<pre><code>
topic_name() = binary()
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#decode_metadata-1">decode_metadata/1</a></td><td></td></tr><tr><td valign="top"><a href="#decode_produce-1">decode_produce/1</a></td><td></td></tr><tr><td valign="top"><a href="#encode_message_set-1">encode_message_set/1</a></td><td></td></tr><tr><td valign="top"><a href="#encode_metadata-3">encode_metadata/3</a></td><td></td></tr><tr><td valign="top"><a href="#encode_produce-7">encode_produce/7</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="decode_metadata-1"></a>

### decode_metadata/1 ###

<pre><code>
decode_metadata(X1::binary()) -&gt; {non_neg_integer(), [<a href="#type-broker">broker()</a>], [<a href="#type-topic_metadata">topic_metadata()</a>]}
</code></pre>
<br />

<a name="decode_produce-1"></a>

### decode_produce/1 ###

<pre><code>
decode_produce(X1::binary()) -&gt; term()
</code></pre>
<br />

<a name="encode_message_set-1"></a>

### encode_message_set/1 ###

<pre><code>
encode_message_set(Messages::binary() | [binary()]) -&gt; iolist()
</code></pre>
<br />

<a name="encode_metadata-3"></a>

### encode_metadata/3 ###

<pre><code>
encode_metadata(CorrelationId::integer(), ClientId::iolist(), Topics::[iolist()]) -&gt; iolist()
</code></pre>
<br />

<a name="encode_produce-7"></a>

### encode_produce/7 ###

<pre><code>
encode_produce(CorrelationId::integer(), ClientId::iolist(), Topic::<a href="#type-topic_name">topic_name()</a>, Partition::non_neg_integer(), Messages::<a href="#type-msg">msg()</a>, Acks::integer(), Compression::<a href="#type-compression">compression()</a>) -&gt; iolist()
</code></pre>
<br />

