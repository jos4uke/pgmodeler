# jtran/pgmodeler:v1
FROM ubuntu:trusty
MAINTAINER Joseph Tran <josndtran@yahoo.fr>
RUN apt-get update && \
        apt-get install -y \
                build-essential pkg-config libpq-dev \
                qtdeclarative5-dev qt5-default \
                libxml2-dev postgresql-9.3 \
                qttools5-dev qttools5-dev-tools \
                wget

ADD libpq.pc /usr/lib/pkgconfig/

# pgmodeler src
RUN mkdir -p /usr/local/src/pgmodeler
WORKDIR "/usr/local/src/pgmodeler"
RUN wget https://github.com/pgmodeler/pgmodeler/archive/v0.8.1.tar.gz && \
        tar -xzvf v0.8.1.tar.gz

# configure plugins: no need to configure directly else make crash
#WORKDIR "/usr/local/src/pgmodeler/pgmodeler-0.8.1/plugins/"
#RUN cd /usr/local/src/pgmodeler/pgmodeler-0.8.1/plugins/ && qmake plugins.pro && make
# configure and install
#WORKDIR "/usr/local/src/pgmodeler/pgmodeler-0.8.1/"
RUN cd /usr/local/src/pgmodeler/pgmodeler-0.8.1/ && qmake pgmodeler.pro && make && make install

# starter script and env vars file
RUN cp /usr/local/src/pgmodeler/pgmodeler-0.8.1/start-pgmodeler.sh /usr/local/bin/. && chmod +x /usr/local/bin/start-pgmodeler.sh
RUN cp /usr/local/src/pgmodeler/pgmodeler-0.8.1/pgmodeler.vars /. && ln -s /pgmodeler.vars /usr/local/bin/pgmodeler.vars

# put a startup script in /etc/rc2.d
# useless because container runlevel is unknown instead of 2 
ADD startup_pgmodeler.sh /etc/init.d/
RUN ln -s  /etc/init.d/startup_pgmodeler.sh /etc/rc2.d/S99startup_pgmodeler.sh

# run pgmodeler
CMD start-pgmodeler.sh

