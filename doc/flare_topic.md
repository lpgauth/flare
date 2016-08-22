

# Module flare_topic #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-buffer_name">buffer_name()</a> ###


<pre><code>
buffer_name() = atom()
</code></pre>




### <a name="type-compression_name">compression_name()</a> ###


<pre><code>
compression_name() = none | snappy
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


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#init-0">init/0</a></td><td></td></tr><tr><td valign="top"><a href="#server-1">server/1</a></td><td></td></tr><tr><td valign="top"><a href="#start-1">start/1</a></td><td></td></tr><tr><td valign="top"><a href="#start-2">start/2</a></td><td></td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="init-0"></a>

### init/0 ###

<pre><code>
init() -&gt; ok
</code></pre>
<br />

<a name="server-1"></a>

### server/1 ###

<pre><code>
server(Topic::<a href="#type-topic_name">topic_name()</a>) -&gt; {ok, <a href="#type-buffer_name">buffer_name()</a>} | {error, atom()}
</code></pre>
<br />

<a name="start-1"></a>

### start/1 ###

<pre><code>
start(Topic::<a href="#type-topic_name">topic_name()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="start-2"></a>

### start/2 ###

<pre><code>
start(Topic::<a href="#type-topic_name">topic_name()</a>, Opts::<a href="#type-topic_opts">topic_opts()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Topic::<a href="#type-topic_name">topic_name()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

