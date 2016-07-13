

# Module flare_queue #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-ext_req_id">ext_req_id()</a> ###


<pre><code>
ext_req_id() = <a href="/Users/lpgauth/Git/flare/_build/default/lib/shackle/doc/shackle.md#type-request_id">shackle:request_id()</a>
</code></pre>




### <a name="type-req_id">req_id()</a> ###


<pre><code>
req_id() = {<a href="erlang.md#type-timestamp">erlang:timestamp()</a>, pid()}
</code></pre>




### <a name="type-request">request()</a> ###


<pre><code>
request() = {<a href="#type-req_id">req_id()</a>, pid()}
</code></pre>




### <a name="type-requests">requests()</a> ###


<pre><code>
requests() = [<a href="#type-request">request()</a>]
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#add-3">add/3</a></td><td></td></tr><tr><td valign="top"><a href="#init-0">init/0</a></td><td></td></tr><tr><td valign="top"><a href="#remove-1">remove/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="add-3"></a>

### add/3 ###

<pre><code>
add(ExtReqId::<a href="#type-ext_req_id">ext_req_id()</a>, PoolName::atom(), Requests::<a href="#type-requests">requests()</a>) -&gt; ok
</code></pre>
<br />

<a name="init-0"></a>

### init/0 ###

<pre><code>
init() -&gt; ok
</code></pre>
<br />

<a name="remove-1"></a>

### remove/1 ###

<pre><code>
remove(ExtReqId::<a href="#type-ext_req_id">ext_req_id()</a>) -&gt; {ok, {atom(), <a href="#type-requests">requests()</a>}} | {error, not_found}
</code></pre>
<br />

