

# Module flare_client #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-state">state()</a> ###


<pre><code>
state() = #state{}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#handle_data-2">handle_data/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_request-2">handle_request/2</a></td><td></td></tr><tr><td valign="top"><a href="#init-0">init/0</a></td><td></td></tr><tr><td valign="top"><a href="#setup-2">setup/2</a></td><td></td></tr><tr><td valign="top"><a href="#terminate-1">terminate/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="handle_data-2"></a>

### handle_data/2 ###

<pre><code>
handle_data(Data::binary(), State::<a href="#type-state">state()</a>) -&gt; {ok, [{pos_integer(), term()}], <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="handle_request-2"></a>

### handle_request/2 ###

<pre><code>
handle_request(Request::term(), State::<a href="#type-state">state()</a>) -&gt; {ok, pos_integer(), binary(), <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="init-0"></a>

### init/0 ###

<pre><code>
init() -&gt; {ok, <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="setup-2"></a>

### setup/2 ###

<pre><code>
setup(Socket::<a href="inet.md#type-socket">inet:socket()</a>, State::<a href="#type-state">state()</a>) -&gt; {ok, <a href="#type-state">state()</a>}
</code></pre>
<br />

<a name="terminate-1"></a>

### terminate/1 ###

<pre><code>
terminate(State::<a href="#type-state">state()</a>) -&gt; ok
</code></pre>
<br />

