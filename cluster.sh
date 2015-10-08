#!/bin/sh

### Environment --------------------------------------------
VERSION=0.1
DEF_SERVER_COUNT=3
DEF_ENSAMBLE="zk"
DEF_CONTAINER="siniida/zookeeper"

### Functions ----------------------------------------------
function env {
	ENSAMBLE=${ENSAMBLE:-${DEF_ENSAMBLE}}
}

### usage --------------------------------------------------
function usage {
	cat << EOF

Usage:
	$(basename ${0}) [<OPTIONS>] COMMAND

Management Apache ZooKeeper containers.

OPTIONS:
	--version, -v           print $(basename ${0}) version.
	--help, -h              print this message.
	--ensamble, -e STRING   specifies ensamble name. (default: ${DEF_ENSAMBLE})

COMMAND:
	start             ensamble start.
	stop              ensamble stop.
	status            print ensamble status.
	help COMMAND      print COMMAND help.

EOF
}

function usage_start {
	cat << EOF

Usage:
	$(basename ${0}) start [<OPTIONS>] [SERVER_COUNT]

ZooKeeper ensamble start.

OPTIONS:
	--container, -c STRING   specifies container. (default: ${DEF_CONTAINER})

SERVER_COUNT:
	specifies ZooKeeper container count. (default: ${DEF_SERVER_COUNT})

EOF
}

function usage_stop {
	cat << EOF

Usage:
	$(basename ${0}) stop

ZooKeeper ensamble stop.

EOF
}

function usage_status {
	cat << EOF

Usage:
	$(basename ${0}) status [<OPTIONS>]

ZooKeeper ensamble status.

OPTIONS:
	--servers, -s   print only container status.
	--link, -l      print only link options. ex) --link ${ENSAMBLE}1:${ENSAMBLE}1 --link..
	--address, -a   print only access string. ex) ${ENSAMBLE}1:2181,${ENSAMBLE}2:2181,...
	--ip, -i        print ip.

EOF
}

### start function -----------------------------------------
function start {
	while [ $# -gt 0 ]
	do
		case ${1} in
			--container|-c)
				CONTAINER=${2}
				shift
				;;
			-*)
				echo "[ERROR] Invalid start option '${1}'"
				exit 1
				;;
			*)
				expr ${1} + 1 > /dev/null 2>&1
				if [ $? -eq 2 ]
				then
					echo "[ERROR] Not a decimal number: SERVER_COUNT."
					exit 1
				fi
				SERVER_COUNT=${1}
				break
				;;
		esac
		shift
	done

	# check
	if [ -f ${ENSAMBLE}.cfg ]
	then
		echo "[ERROR] ZooKeeper ensamble already exists. check '${ENSAMBLE}.cfg'."
		exit 1
	fi

	# docker run
	for i in `seq 1 ${SERVER_COUNT:-${DEF_SERVER_COUNT}}`
	do
		docker run -d \
			-e MYID=${i} \
			--restart=always \
			--name=${ENSAMBLE}${i} \
			--hostname=${ENSAMBLE}${i} \
			${CONTAINER:-${DEF_CONTAINER}}
	done

	# check
	if [ $? -ne 0 ]
	then
		echo "[ERROR] check docker."
		exit 1
	fi

	# create config file
	for i in `seq 1 ${SERVER_COUNT:-${DEF_SERVER_COUNT}}`
	do
		CONTAINER_IP=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' ${ENSAMBLE}${i})
		echo "server.${i}=${CONTAINER_IP}:2888:3888" >> ${ENSAMBLE}.cfg
	done

	# append zoo.cfg
	for i in `seq 1 ${SERVER_COUNT:-${DEF_SERVER_COUNT}}`
	do
		docker exec -i ${ENSAMBLE}${i} \
			/bin/bash -c "cat >> /opt/zookeeper/conf/zoo.cfg" < ${ENSAMBLE}.cfg
	done

	exit $?
}

### stop function ------------------------------------------
function stop {
	if [ ! -f ${ENSAMBLE}.cfg ]
	then
		echo "[ERROR] '${ENSAMBLE}' ensamble not started."
		exit 1
	fi

	SERVER_COUNT=`wc -l ${ENSAMBLE}.cfg | awk '{print $1}'`
	for i in `seq 1 ${SERVER_COUNT}`
	do
		docker stop ${ENSAMBLE}${i} > /dev/null 2>&1
		docker rm ${ENSAMBLE}${i} > /dev/null 2>&1
	done

	rm ${ENSAMBLE}.cfg
	exit $?
}

### status function ----------------------------------------
function status {
	if [ ! -f ${ENSAMBLE}.cfg ]
	then
		echo "[ERROR] '${ENSAMBLE}' ensamble not started."
		exit 1
	fi

	while [ $# -gt 0 ]
	do
		case ${1} in
			--servers|-s)
				OPT_SERVERS=true
				;;
			--link|-l)
				OPT_LINK=true
				;;
			--address|-a)
				OPT_ADDRESS=true
				;;
			--ip|-i)
				OPT_IP=true
				;;
		esac
		shift
	done

	SERVER_COUNT=`wc -l ${ENSAMBLE}.cfg | awk '{print $1}'`

	if [ ! -n "${OPT_LINK}" -a ! -n "${OPT_ADDRESS}" ]
	then
		for i in `seq 1 ${SERVER_COUNT}`
		do
				docker ps -f name=${ENSAMBLE}${i} \
					--format "${ENSAMBLE}${i}({{.ID}}): {{.Status}}"
		done
	fi

	if [ ! -n "${OPT_SERVERS}" -a ! -n "${OPT_ADDRESS}" ]
	then
		for i in `seq 1 ${SERVER_COUNT}`
		do
			LINK_STR="${LINK_STR} --link ${ENSAMBLE}${i}:${ENSAMBLE}${i}"
		done
		echo ${LINK_STR}
	fi

	if [ ! -n "${OPT_SERVERS}" -a ! -n "${OPT_LINK}" ]
	then
		if [ -n "${OPT_IP}" ]
		then
			for i in `seq 1 ${SERVER_COUNT}`
			do
				CONTAINER_IP=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' ${ENSAMBLE}${i})
				ADDRESS_STR="${ADDRESS_STR},${CONTAINER_IP}:2181"
			done
		else
			for i in `seq 1 ${SERVER_COUNT}`
			do
				ADDRESS_STR="${ADDRESS_STR},${ENSAMBLE}${i}:2181"
			done
		fi
		echo ${ADDRESS_STR:1}
	fi

	exit $?
}

### Main ---------------------------------------------------

while [ $# -gt 0 ]
do
	case ${1} in
		--version|-v)
			echo "$(basename ${0}): ${VERSION}"
			exit 0
			;;
		--help|-h)
			usage
			exit 0
			;;
		--debug|-d)
			set -x
			;;
		--ensamble|-e)
			ENSAMBLE=${2}
			shift
			;;
		start|stop|status)
			COMMAND=${1}
			shift
			env
			${COMMAND} $@
			;;
		help)
			case ${2} in
				start|stop|status)
					usage_${2}
					exit 0
					;;
				"")
					usage
					;;
				*)
					echo "[ERROR] Invalid command '${2}'"
					exit 1
					;;
			esac
			exit 0
			;;
		*)
			echo "[ERROR] Invalid command or option '${1}'"
			exit 1
			;;
	esac
	shift
done

echo "[ERROR] Not specifies COMMAND."
usage

# EOF
