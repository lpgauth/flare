

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




### <a name="type-topic_name">topic_name()</a> ###


<pre><code>
topic_name() = binary()
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#produce-2">produce/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="produce-2"></a>

### produce/2 ###

<pre><code>
produce(Topic::<a href="#type-topic_name">topic_name()</a>, Msg::<a href="#type-msg">msg()</a>) -&gt; ok | {error, atom()}
</code></pre>
<br />

