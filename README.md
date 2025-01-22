# kafka-tools

A collection of miscellaneous tools for making it easier to work with (Apache) Kafka.

## Quickstart

### Running Kafka locally

There are [official instructions](https://kafka.apache.org/quickstart) for running Apache Kafka in different modes (KRaft in Docker, ZooKeeper in Docker, etc.).
The KRaft in Docker setup can be run with:
```sh
KAFKA_VERSION=3.9.0
docker pull apache/kafka:${KAFKA_VERSION}
docker run -p 9092 apache/kafka:${KAFKA_VERSION}
```

### kcat (formerly kafkacat)

`kcat` is available as a Docker image, if you do not have it already installed locally.
The 1.7.1 [edenhill/kcat image](https://hub.docker.com/r/edenhill/kcat/tags) is under 17MB (compressed).

```sh
KCAT_VERSION=1.7.1
docker pull edenhill/kcat:${KCAT_VERSION}
docker run --network=host --rm edenhill/kcat:${KCAT_VERSION} -b localhost:9092 -L
```

You should see something like:
```
Metadata for all topics (from broker 1: localhost:9092/1):
 1 brokers:
  broker 1 at localhost:9092 (controller)
 0 topics:
```

You can then create some dummy messages and confirm they have been written using:
```sh
echo 'data' | docker run --rm -i --network=host edenhill/kcat:1.7.1 -b localhost:9092 -t test -K: -P
docker run --rm -it --network=host edenhill/kcat:1.7.1 -b localhost:9092 -t test -CeJq
```

That `-CeqJ` at the end means:
* run in consumer mode,
* read messages until the end of the topic then stop,
* output messages in JSON format, so we can see the headers as well as the message bodies,
* and do not output informational logs, as this would be annoying for use with `jq`.

You should see something like:
```json
{"topic":"test","partition":0,"offset":1,"tstype":"create","ts":1737461938187,"broker":1,"key":null,"payload":"data"}
```

As it can be annoying to work with long commands, you may wish to add an alias like the below to your `~/.bashrc` or equivalent:
```bash
alias kcat='docker run --rm --network=host edenhill/kcat:1.7.1'
```

## jq functions

There are `jq` functions defined in `kafka.jq`.
These can be imported into a `jq` script using `include "./kafka";` at the start, assuming you are running from the root of this repository.

### Timestamp conversion

One of the `jq` functions is `ts_to_date`, which converts Kafka timestamps, given as milliseconds since the Unix epoch, into human-readable dates.
Millisecond precision is retained.

Example:
```bash
docker run --rm --network=host edenhill/kcat:1.7.1 -b localhost:9092 -t test -CeqJ \
  | jq 'include "./kafka"; [.ts, ts_to_date]'
```
```json
[
  1737461938187,
  "2025-01-21T12:18:58.187Z"
]
```

### Headers

_For this section, you may wish to restart the Kafka instance(s) set up previously as a quick means of deleting the test topic (and its contents)._

First, ensure a message is created with headers:
```
echo 'data' | kcat -b localhost:9092 -t test -P -H foo=bar -H foo=baz -H quux=5
kcat -b localhost:9092 -t test -CeqJ
```
The output should look similar to:
```json
{
  "topic": "test",
  "partition": 0,
  "offset": 0,
  "tstype": "create",
  "ts": 1737468354865,
  "broker": 1,
  "headers": [
    "foo",
    "bar",
    "foo",
    "baz",
    "quux",
    "5"
  ],
  "key": null,
  "payload": "data"
}
```

Kafka headers are given as a flat list, whereas we typically think of them as key/value pairs.
Note that the above message has a _repeated_ header key, `foo`, which is valid usage.

This repository defines another `jq` function, called `headers`, which performs this transformation from list to map, accounting for repeated keys.
Example:
```bash
kcat -b localhost:9092 -t test -CeqJ \
  | jq 'include "./kafka"; headers'
```
```json
{
  "foo": [
    "bar",
    "baz"
  ],
  "quux": [
    "5"
  ]
}
```
