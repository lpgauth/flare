# flare

High Performance Erlang Kafka Producer

[![Build Status](https://travis-ci.org/lpgauth/flare.svg?branch=master)](https://travis-ci.org/lpgauth/flare)
[![Coverage Status](https://coveralls.io/repos/github/lpgauth/flare/badge.svg?branch=master)](https://coveralls.io/github/lpgauth/flare?branch=master)

#### Features

* Compression support (snappy)
* Performance optimized
* Topic buffering (delay, size)

## API
<a href="http://github.com/lpgauth/flare/blob/master/doc/flare.md#index" class="module">Function Index</a>

#### Environment variables

<table width="100%">
  <theader>
    <th>Name</th>
    <th>Type</th>
    <th>Default</th>
    <th>Description</th>
  </theader>
  <tr>
    <td>broker_bootstrap_servers</td>
    <td>[{inet:ip_address() | inet:hostname(), inet:port_number()}]</td>
    <td>[{"127.0.0.1", 9092}]</td>
    <td>Bootstrap servers used to query topic metadata</td>
  </tr>
  <tr>
    <td>broker_pool_size</td>
    <td>pos_integer()</td>
    <td>2</td>
    <td>Number of connections per broker</td>
  </tr>
  <tr>
    <td>broker_pool_strategy</td>
    <td>random | round_robin</td>
    <td>random</td>
    <td>Broker connection selection strategy</td>
  </tr>
  <tr>
    <td>broker_reconnect</td>
    <td>boolean()</td>
    <td>true</td>
    <td>Reconnect closed broker connections</td>
  </tr>
  <tr>
    <td>broker_reconnect_time_max</td>
    <td>pos_integer() | infinity</td>
    <td>120000</td>
    <td>Maximum reconnect time (milliseconds)</td>
  </tr>
  <tr>
    <td>broker_reconnect_time_min</td>
    <td>non_neg_integer()</td>
    <td>0</td>
    <td>Minimum reconnect time (milliseconds)</td>
  </tr>
</table>

#### Topic options

<table width="100%">
  <theader>
    <th>Name</th>
    <th>Type</th>
    <th>Default</th>
    <th>Description</th>
  </theader>
  <tr>
    <td>acks</td>
    <td>0..65535</td>
    <td>1</td>
    <td>Number of acknowledgements required for a succeful produce </td>
  </tr>
  <tr>
    <td>buffer_delay</td>
    <td>pos_integer()</td>
    <td>1000</td>
    <td>Maximun delay (milliseconds) before flushing the buffer</td>
  </tr>
  <tr>
    <td>buffer_size</td>
    <td>pos_integer()</td>
    <td>10000</td>
    <td>Maximun buffer size (bytes) before flushing</td>
  </tr>
  <tr>
    <td>compression</td>
    <td>none | snappy</td>
    <td>snappy</td>
    <td>Compression configuration</td>
  </tr>
  <tr>
    <td>metadata_delay</td>
    <td>pos_integer()</td>
    <td>60000</td>
    <td>Maximun delay (milliseconds) before reloading metadata</td>
  </tr>
  <tr>
    <td>pool_size</td>
    <td>pos_integer()</td>
    <td>2</td>
    <td>Number of topic buffer proccesses</td>
  </tr>
</table>

## Examples

```erlang
1> flare_app:start().
{ok,[shackle,flare]}
2> TopicOpts = [{acks, 1}, {compression, snappy}, {buffer_size, 1000000}, {pool_size, 8}].
[{acks,1},
 {compression,snappy},
 {buffer_size,1000000},
 {pool_size,8}]
3> flare_topic:start(<<"my topic">>, TopicOpts).
ok
4> flare:produce(<<"my topic">>, <<"my msg">>).
ok
5> {ok, ReqId} = flare:async_produce(<<"test">>, <<"hello">>).
{ok,{{1468,419385,705022},<0.146.0>}}
6> flare:receive_response(ReqId).
ok
7> flare_topic:stop(<<"my topic">>).
ok
```

## Tests

```makefile
make dialyzer
make elvis
make eunit
make xref
```

## Performance testing

To run the profile target you must first start kafka:

```
./bin/zookeeper-server-start.sh config/zookeeper.properties &
./bin/kafka-server-start.sh config/server.properties &
```

Then you can run the profile target:

```makefile
make profile
```

## License

```license
The MIT License (MIT)

Copyright (c) 2016 Louis-Philippe Gauthier

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
