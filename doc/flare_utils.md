

# Module flare_utils #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-compression">compression()</a> ###


<pre><code>
compression() = 0 | 2
</code></pre>




### <a name="type-compression_name">compression_name()</a> ###


<pre><code>
compression_name() = none | snappy
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#compress-2">compress/2</a></td><td></td></tr><tr><td valign="top"><a href="#compression-1">compression/1</a></td><td></td></tr><tr><td valign="top"><a href="#send_recv-3">send_recv/3</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="compress-2"></a>

### compress/2 ###

<pre><code>
compress(X1::<a href="#type-compression">compression()</a>, Messages::iolist()) -&gt; iolist()
</code></pre>
<br />

<a name="compression-1"></a>

### compression/1 ###

<pre><code>
compression(X1::<a href="#type-compression_name">compression_name()</a>) -&gt; <a href="#type-compression">compression()</a>
</code></pre>
<br />

<a name="send_recv-3"></a>

### send_recv/3 ###

<pre><code>
send_recv(Ip::<a href="inet.md#type-socket_address">inet:socket_address()</a> | <a href="inet.md#type-hostname">inet:hostname()</a>, Port::<a href="inet.md#type-port_number">inet:port_number()</a>, Data::iodata()) -&gt; {ok, binary()} | {error, term()}
</code></pre>
<br />

