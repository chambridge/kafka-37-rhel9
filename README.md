# kafka-37-rhel9
Run kafka-37-rhel9 from containers


# Getting Started

This is initially focused on standing up a kafka with containers. Below provides two options, one using Zoo Keeper and the other using KRaft.

## Zookeeper

Below is the zookeeper setup.

### Launch with podman compose

If you are familiar with compose files you can find the definition of the containers and the associated minimal configuration for each component in the `kafka-config` and `zookeeper-config` directories respectively.

#### Launch the containers:

```
podman compose -f compose-zookeeper.yml up
```

#### Test the capability

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

### Quadlet files

I have provided the following quadlet files:

- `zookeeper.container`
- `kafka.container`
- `kafka-network.network`


## KRaft

Below is the kraft setup.

### Launch with podman compose

If you are familiar with compose files you can find the definition of the containers and the associated minimal configuration in the `kafka-config/kraft` directory.

#### Format KRaft

Run the following command to initialize the KRaft setup:

```
podman run --rm -it -v ./kafka-config/kraft:/opt/kafka/config/kraft:Z -v ./kafka-data:/var/lib/kafka/data:Z registry.redhat.io/amq-streams/kafka-37-rhel9:2.8.0 bash -c "bin/kafka-storage.sh format -t 23da142e-8175-4b5d-b3aa-fa307f12a8c2 -c config/kraft/server.properties"
```

The UUID can be replaced with any UUID, the `bin/kafka-storage.sh random-uuid` command can also be used to generate this value.

#### Launch the containers:

```
podman compose -f compose-kraft.yml up
```


#### Test the capability

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

### Quadlet files

I have provided the following quadlet files:

- `kafka-kraft.container`
- `kafka-network.network`

