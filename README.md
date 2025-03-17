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
podman exec -it kafka /bin/bash
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
podman exec -it kafka /bin/bash
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

Below is the KRaft setup.

### Launch with podman compose

If you are familiar with compose files you can find the definition of the containers and the associated minimal configuration in the `kafka-config/kraft` directory.

#### Format KRaft

Run the following command to initialize the KRaft setup:

```
podman run --rm -it -v ./kafka-config/kraft:/opt/kafka/config/kraft:Z -v ./kafka-data:/var/lib/kafka/data:Z registry.redhat.io/amq-streams/kafka-39-rhel9:2.9.0 bash -c "bin/kafka-storage.sh format -t 23da142e-8175-4b5d-b3aa-fa307f12a8c2 -c config/kraft/server.properties"
```

The UUID can be replaced with any UUID, the `bin/kafka-storage.sh random-uuid` command can also be used to generate this value.

#### Launch the containers:

```
podman compose -f compose-kraft.yml up
```


#### Test the capability

Start by creating a topic. In another terminal run the following to run the terminal for the kafka container:

```
podman exec -it kafka /bin/bash
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
podman exec -it kafka /bin/bash
```

And then listen for the messages with the following command:

```
bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --from-beginning
```

### Quadlet files

I have provided the following quadlet files:

- `kafka-kraft.container`
- `kafka-network.network`


## KRaft with mTLS

Below is the KRaft setup utilizing mTLS.

### Generate certificates for communications

In order to utilize mTLS communication you need server and client certificates in formats commonly used by Kafka server and clients respectively. The following script will enable the generation of those artifacts. All artifacts are self-signed as it will also generate a Certificate Authority certificate if one doesn't already exist. Within the script there is a `PASSWORD` variable hardcoded to `yourpassword` which should be updated for your usage; you will also need to update the `server.properties` file and `mtls-config.properties` file entries to match.

Run the following command to generate the necessary certificates, which will be placed in the `./certs` directory and will be mounted by the Kafka container:

```
./generate-certs.sh
```

### Launch with podman compose

If you are familiar with compose files you can find the definition of the containers and the associated minimal configuration in the `kafka-config/kraft-mtls` directory.

If you are on macOS you will want to setup the following environment variables to be used by the container user string for proper file system ownership:
```
export UID=$(id -u)
export GID=$(id -g)
```

#### Format KRaft

Run the following command to initialize the KRaft setup:

```
podman run --rm -it -v ./kafka-config/kraft-mtls:/opt/kafka/config/kraft:Z -v ./kafka-data:/var/lib/kafka/data:Z registry.redhat.io/amq-streams/kafka-39-rhel9:2.9.0 bash -c "bin/kafka-storage.sh format -t 23da142e-8175-4b5d-b3aa-fa307f12a8c2 -c config/kraft/server.properties"
```

The UUID can be replaced with any UUID, the `bin/kafka-storage.sh random-uuid` command can also be used to generate this value.

MacOS users may need to add the -u flag so the container has the appropriate file system ownership of the cert files:
```
podman run --rm -u "${UID}:${GID}" -it -v ./kafka-config/kraft-mtls:/opt/kafka/config/kraft:Z -v ./kafka-data:/var/lib/kafka/data:Z registry.redhat.io/amq-streams/kafka-39-rhel9:2.9.0 bash -c "bin/kafka-storage.sh format -t 23da142e-8175-4b5d-b3aa-fa307f12a8c2 -c config/kraft/server.properties"
```


#### Launch the containers:

MacOS users will want to uncomment the `user` property on line 7, in order for the container to have proper ownership of the certificate files.

```
podman compose -f compose-kraft-mtls.yml up
```

#### Test the capability

Start by creating a topic. In another terminal run the following to run the terminal for the kafka container:

```
podman exec -it kafka-mtls /bin/bash
```

Create the topic with the following command which makes use of the mounted `mtls-config.properties` file:

```
bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --command-config /tmp/mtls-config.properties --partitions 1 replication-factor 1
```

Produce a message on the topic:

```
bin/kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092 --producer.config /tmp/mtls-config.properties
```

Type in a message (`helloworld`) and `Ctrl-C` to finish the message.

In a separate terminal launch another terminal for the kafka container to use as a consumer:

```
podman exec -it kafka-mtls /bin/bash
```

And then listen for the messages with the following command:

```
bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --consumer.config /tmp/mtls-config.properties --from-beginning
```

### Quadlet files

I have provided the following quadlet files:

- `kafka-kraft-mtls.container`
- `kafka-network.network`
