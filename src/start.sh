#!/bin/bash


# Accept listen_address
IP=`hostname --ip-address`

# Accept seeds via docker run -e SEEDS=seed1,seed2,...
SEEDS=${SEEDS:-$IP}

#if this container was linked to any other cassandra nodes, use them as seeds as well.
if [[ `env | grep _PORT_9042_TCP_ADDR` ]]; then
  SEEDS="$SEEDS,$(env | grep _PORT_9042_TCP_ADDR | sed 's/.*_PORT_9042_TCP_ADDR=//g' | sed -e :a -e N -e 's/\n/,/' -e ta)"
fi

echo Configuring Cassandra to listen at $IP with seeds $SEEDS

# Setup Cassandra
CONFIG=/opt/cassandra/conf

sed -i -e "s/^listen_address.*/listen_address: $IP/"            $CONFIG/cassandra.yaml
sed -i -e "s/^rpc_address.*/rpc_address: 0.0.0.0/"              $CONFIG/cassandra.yaml
sed -i -e "s/# broadcast_address.*/broadcast_address: $IP/"              $CONFIG/cassandra.yaml
sed -i -e "s/# broadcast_rpc_address.*/broadcast_rpc_address: $IP/"              $CONFIG/cassandra.yaml
sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/"       $CONFIG/cassandra.yaml
sed -i -e "s/# JVM_OPTS=\"$JVM_OPTS -Djava.rmi.server.hostname=<public name>\"/ JVM_OPTS=\"$JVM_OPTS -Djava.rmi.server.hostname=$IP\"/" $CONFIG/cassandra-env.sh

if [[ $SNITCH ]]; then
  sed -i -e "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: $SNITCH/" $CONFIG/cassandra.yaml
else
  sed -i -e "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: GossipingPropertyFileSnitch/" $CONFIG/cassandra.yaml
fi

if [[ $DC && $RACK ]]; then
  echo "dc=$DC" > $CONFIG/cassandra-rackdc.properties
  echo "rack=$RACK" >> $CONFIG/cassandra-rackdc.properties
elif [[ $DC ]]; then
  echo "dc=$DC" > $CONFIG/cassandra-rackdc.properties
  echo "rack=RAC1" >> $CONFIG/cassandra-rackdc.properties
fi

# Start process
echo Starting Cassandra on $IP...
/opt/cassandra/bin/cassandra -f
