# siniida/zookeeper

[![](https://badge.imagelayers.io/siniida/zookeeper:latest.svg)](https://imagelayers.io/?images=siniida/zookeeper:latest 'Get your own badge on imagelayers.io')

for gennai cluster. ([gennai.docker](https://github.com/siniida/gennai.docker))

## Standalone ZooKeeper

    $ docker run -d siniida/zookeeper

## ZooKeeper Ensamble

    Usage:
      cluster.sh [<OPTIONS>] COMMAND
    
    Management Apache ZooKeeper containers.
    
    OPTIONS:
      --version, -v           print cluster.sh version.
	  --help, -h              print this message.
	  --ensamble, -e STRING   specifies ensamble name. (default: zk)
    
    COMMAND:
	  start             ensamble start.
      stop              ensamble stop.
      status            print ensamble status.
      help COMMAND      print COMMAND help.

### Create ZooKeeper Ensamble

    Usage:
      cluster.sh start [<OPTIONS>] [SERVER_COUNT]
    
    ZooKeeper ensamble start.
    
    OPTIONS:
      --container, -c STRING   specifies container. (default: siniida/zookeeper)
    
    SERVER_COUNT:
      specifies ZooKeeper container count. (default: 3)

ex)

    $ ./cluster.sh start 5

means

    $ docker run -d --name=zk1 --hostname=zk1 --restart=always siniida/zookeeper
    $ docker run -d --name=zk2 --hostname=zk2 --restart=always siniida/zookeeper
    $ docker run -d --name=zk3 --hostname=zk3 --restart=always siniida/zookeeper
    $ docker run -d --name=zk4 --hostname=zk4 --restart=always siniida/zookeeper
    $ docker run -d --name=zk5 --hostname=zk5 --restart=always siniida/zookeeper
    
### Get ZooKeeper Ensamble status

    Usage:
      cluster.sh status [<OPTIONS>]
    
    ZooKeeper ensamble status.
    
    OPTIONS:
      --servers, -s   print only container status.
      --link, -l      print only link options. ex) --link 1:1 --link..
      --address, -a   print only access string. ex) 1:2181,2:2181,...
      --ip, -i        print ip.

### Destroy ZooKeeper Ensamble

    Usage:
      cluster.sh stop
    
    ZooKeeper ensamble stop.
