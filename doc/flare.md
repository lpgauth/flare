

# Module flare #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-msg">msg()</a> ###


<pre><code>
msg() = binary()
</code></pre>




### <a name="type-req_id">req_id()</a> ###


<pre><code>
req_id() = {<a href="erlang.md#type-timestamp">erlang:timestamp()</a>, pid()}
</code></pre>




### <a name="type-topic_name">topic_name()</a> ###


<pre><code>
topic_name() = binary()
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#async_produce-2">async_produce/2</a></td><td></td></tr><tr><td valign="top"><a href="#async_produce-3">async_produce/3</a></td><td></td></tr><tr><td valign="top"><a href="#produce-2">produce/2</a></td><td></td></tr><tr><td valign="top"><a href="#produce-3">produce/3</a></td><td></td></tr><tr><td valign="top"><a href="#receive_response-1">receive_response/1</a></td><td></td></tr><tr><td valign="top"><a href="#receive_response-2">receive_response/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="async_produce-2"></a>

### async_produce/2 ###

<pre><code>
async_produce(Topic::<a href="#type-topic_name">topic_name()</a>, Message::<a href="#type-msg">msg()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="async_produce-3"></a>

### async_produce/3 ###

<pre><code>
async_produce(Topic::<a href="#type-topic_name">topic_name()</a>, Message::<a href="#type-msg">msg()</a>, Pid::pid()) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="produce-2"></a>

### produce/2 ###

<pre><code>
produce(Topic::<a href="#type-topic_name">topic_name()</a>, Message::<a href="#type-msg">msg()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="produce-3"></a>

### produce/3 ###

<pre><code>
produce(Topic::<a href="#type-topic_name">topic_name()</a>, Message::<a href="#type-msg">msg()</a>, Timeout::pos_integer()) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="receive_response-1"></a>

### receive_response/1 ###

<pre><code>
receive_response(ReqId::<a href="#type-req_id">req_id()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="receive_response-2"></a>

### receive_response/2 ###

<pre><code>
receive_response(ReqId::<a href="#type-req_id">req_id()</a>, Timeout::pos_integer()) -&gt; ok | {error, atom()}
</code></pre>
<br />

