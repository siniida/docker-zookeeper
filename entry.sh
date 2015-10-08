#!/bin/sh

# myid
if [ -n "${MYID}" ] ; then
	echo "${MYID}" > /opt/zookeeper/data/myid

	echo "waiting zoo.cfg changing.."

	# wait ensamble config..
	# ex) docker exec ${HOSTNAME} -c "echo server.${MYID}=${IP}:2888:3888 >> zoo.cfg"
	while [ $(grep -c server.${MYID} /opt/zookeeper/conf/zoo.cfg) -lt 1 ]
	do
		sleep 1
	done

	echo "zoo.cfg changed. starting ZooKeeper server."
fi

exec "$@"
