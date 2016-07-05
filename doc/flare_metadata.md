

# Module flare_metadata #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-broker">broker()</a> ###


<pre><code>
broker() = #broker{node_id = non_neg_integer(), host = binary(), port = pos_integer()}
</code></pre>




### <a name="type-partition_id">partition_id()</a> ###


<pre><code>
partition_id() = non_neg_integer()
</code></pre>




### <a name="type-topic_name">topic_name()</a> ###


<pre><code>
topic_name() = binary()
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#partitions-1">partitions/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="partitions-1"></a>

### partitions/1 ###

<pre><code>
partitions(Topic::<a href="#type-topic_name">topic_name()</a>) -&gt; {ok, [{<a href="#type-partition_id">partition_id()</a>, atom(), <a href="#type-broker">broker()</a>}]} | {error, term()}
</code></pre>
<br />

