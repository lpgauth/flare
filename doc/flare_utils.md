

# Module flare_utils #
* [Function Index](#index)
* [Function Details](#functions)

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#ets_lookup_element-2">ets_lookup_element/2</a></td><td></td></tr><tr><td valign="top"><a href="#send_recv-3">send_recv/3</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="ets_lookup_element-2"></a>

### ets_lookup_element/2 ###

<pre><code>
ets_lookup_element(Table::atom(), Key::term()) -&gt; term()
</code></pre>
<br />

<a name="send_recv-3"></a>

### send_recv/3 ###

<pre><code>
send_recv(Ip::<a href="inet.md#type-socket_address">inet:socket_address()</a> | <a href="inet.md#type-hostname">inet:hostname()</a>, Port::<a href="inet.md#type-port_number">inet:port_number()</a>, Data::iodata()) -&gt; {ok, binary()} | {error, term()}
</code></pre>
<br />

