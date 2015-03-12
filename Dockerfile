# Cassandra
#
# VERSION               1.0

FROM wederbrand/java7
MAINTAINER Andreas Wederbrand andreas@wederbrand.se

RUN mkdir -p /opt
WORKDIR /opt
RUN curl -L http://downloads.datastax.com/community/dsc-cassandra-2.1.3-bin.tar.gz | tar xz
RUN ln -s dsc-cassandra-2.1.3 cassandra
RUN rm -rf cassandra/data/system/*

RUN rm -f /etc/security/limits.d/cassandra.conf

ENV PATH $PATH:/opt/cassandra/bin
# can be removed later
ENV TERM xterm 

ADD src/start.sh /usr/local/bin/start

EXPOSE 7000 7001 7199 9042 9160

USER root
CMD start
