# kafka-37-rhel9
Run kafka-37-rhel9 from containers


# Getting Started

This is initially focused on standing up a local zookeeper and kafka with single containers.

## Launch with podman compose

If you are familiar with compose files you can find the definition of the containers and the associated minimal configuration for each component in the `kafka-config` and `zookeeper-config` directories respectively.

### Launch the containers:

```
podman compose up
```

### Test the capability

Start by creating a topic. In another terminal run the following to run the terminal for the kafka container:

```
podman exec -it kafka bash
```

Create the topic with the following command:

```
bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 replication-factor 1
```

Produce a message on the topic:

```
bin/kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092
```

Type in a message (`helloworld`) and `Ctrl-C` to finish the message.

In a separate terminal launch another terminal for the kafka container to use as a consumer:

```
podman exec -it kafka bash
```

And then listen for the messages with the following command:

```
bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --from-beginning
```

## Quadlet files

I have provided the following quadlet files:

- `zookeeper.container`
- `kafka.container`
- `kafka-network.network`

