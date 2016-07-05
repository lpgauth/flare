

# Module flare_broker_pool #
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

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#start-1">start/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="start-1"></a>

### start/1 ###

<pre><code>
start(T::[{<a href="#type-partition_id">partition_id()</a>, atom(), <a href="#type-broker">broker()</a>}]) -&gt; ok
</code></pre>
<br />

