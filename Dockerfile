FROM centos:6
MAINTAINER siniida <sinpukyu@gmail.com>

ENV ZOO_VERSION=3.4.8

RUN yum update -y \
    && yum install -y tar

RUN curl -L -O -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jre-7u80-linux-x64.rpm \
    && rpm -ivh jre-7u80-linux-x64.rpm && rm jre-7u80-linux-x64.rpm

RUN curl http://archive.apache.org/dist/zookeeper/zookeeper-${ZOO_VERSION}/zookeeper-${ZOO_VERSION}.tar.gz | tar zx -C /opt \
    && ln -s /opt/zookeeper-${ZOO_VERSION} /opt/zookeeper \
    && mkdir /opt/zookeeper/data \
    && chown -R root:root /opt/zookeeper-${ZOO_VERSION} \
    && mv /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg \
    && sed -i \
      -e 's/^\(dataDir\)=.*/\1=\/opt\/zookeeper\/data/g' \
      -e 's/^#\(autopurge.snapRetainCount=.*\)/\1/g' \
      -e 's/^#\(autopurge.purgeInterval=.*\)/\1/g' \
      /opt/zookeeper/conf/zoo.cfg
RUN yum clean all

ENV JAVA_HOME /usr/java/default

EXPOSE 2181 2888 3888

WORKDIR /opt/zookeeper

ADD entry.sh /

ENTRYPOINT ["/entry.sh"]
CMD ["/opt/zookeeper/bin/zkServer.sh", "start-foreground"]
