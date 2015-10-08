FROM centos:6
MAINTAINER siniida <sinpukyu@gmail.com>

RUN yum update -y
RUN yum install -y tar

RUN curl -L -O -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm
RUN rpm -ivh jdk-7u80-linux-x64.rpm && rm jdk-7u80-linux-x64.rpm

RUN curl http://ftp.tsukuba.wide.ad.jp/software/apache/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar zx -C /opt
RUN ln -s /opt/zookeeper-3.4.6 /opt/zookeeper
RUN mkdir /opt/zookeeper/data
RUN chown -R root:root /opt/zookeeper-3.4.6
RUN mv /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
RUN sed -i \
  -e 's/^\(dataDir\)=.*/\1=\/opt\/zookeeper\/data/g' \
  -e 's/^#\(autopurge.snapRetainCount=.*\)/\1/g' \
  -e 's/^#\(autopurge.purgeInterval=.*\)/\1/g' \
  /opt/zookeeper/conf/zoo.cfg

ENV JAVA_HOME /usr/java/default

EXPOSE 2181 2888 3888

WORKDIR /opt/zookeeper

ADD entry.sh /opt/zookeeper/bin/

ENTRYPOINT ["/opt/zookeeper/bin/entry.sh"]
CMD ["/opt/zookeeper/bin/zkServer.sh", "start-foreground"]
