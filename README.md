# flare

High Performance Erlang Kafka Producer

[![Build Status](https://travis-ci.org/lpgauth/flare.svg?branch=master)](https://travis-ci.org/lpgauth/flare)
[![Coverage Status](https://coveralls.io/repos/github/lpgauth/flare/badge.svg?branch=master)](https://coveralls.io/github/lpgauth/flare?branch=master)

#### Features

* Backpressure via backlog (OOM protection)
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
    <td>4</td>
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
    <td>120000 (120s)</td>
    <td>Maximum reconnect time (milliseconds)</td>
  </tr>
  <tr>
    <td>broker_reconnect_time_min</td>
    <td>non_neg_integer()</td>
    <td>2000 (2s)</td>
    <td>Minimum reconnect time (milliseconds)</td>
  </tr>
  <tr>
    <td>query_api_versions</td>
    <td>boolean()</td>
    <td>true</td>
    <td>Set to false when using Kafka version 0.9 or less</td>
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
    <td>-1..1 | all_isr | none | leader_only</td>
    <td>1</td>
    <td>Number of acknowledgements required for a succeful produce </td>
  </tr>
  <tr>
    <td>buffer_delay</td>
    <td>pos_integer()</td>
    <td>1000 (1s)</td>
    <td>Maximun delay (milliseconds) before flushing the buffer</td>
  </tr>
  <tr>
    <td>buffer_size</td>
    <td>pos_integer()</td>
    <td>100000</td>
    <td>Maximun buffer size before flushing</td>
  </tr>
  <tr>
    <td>compression</td>
    <td>no_compression | gzip | snappy</td>
    <td>gzip</td>
    <td>Compression configuration</td>
  </tr>
  <tr>
    <td>metadata_delay</td>
    <td>pos_integer()</td>
    <td>300000 (300 s)</td>
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
{ok, [metal, compiler, syntax_tools, foil, granderl, shackle, flare]}
2> flare_topic:start(<<"my_topic">>, [{compression, snappy}]).
ok
3> Timestamp = flare_utils:timestamp().
1548011068201
4> flare:produce(<<"my_topic">>, Timestamp, <<"key">>, <<"value">>, [], 500).
ok
5> {ok, ReqId} = flare:async_produce(<<"my_topic">>, Timestamp, <<"key">>, <<"value">>, [], self()).
{ok, {{1548, 11081, 884262}, <0.349.0>}}
6> flare:receive_response(ReqId, 500).
ok
7> flare:receive_response(ReqId, 500).
ok
8> flare_topic:stop(<<"my_topic">>).
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

Copyright (c) 2016-2019 Louis-Philippe Gauthier

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
