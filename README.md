# pgmodeler
Docker resources to build pgmodeler image

Works on OSX 10.6.8 Snow Leopard

## Step 1: install virtualbox

[Download virtualbox](https://www.virtualbox.org/wiki/Downloads)

Mise à jour de Virtualbox 4.3.30: OK

```
VBoxManage -v
4.3.30r101610

```

## Step 2: install Docker and boot2docker

```
# using brew
brew update

# install docker
brew install docker

# install boot2docker
brew install boot2docker

# version
boot2docker version

```

## Step 3: Initialize and start boot2docker

```
# init
boot2docker -v init

# boot
boot2docker up

```

## Step 4: Set docker environment variables

```
# set in bash_profile.common
vim .bashrc 

// ...
# add these lines
    export DOCKER_HOST=tcp://192.168.59.103:2376
    export DOCKER_CERT_PATH=$HOME/.boot2docker/certs/boot2docker-vm
    export DOCKER_TLS_VERIFY=1
// ...

# source env
source .bashrc 

```

## Step 5: Profit

```
# info
docker info

# Docker Host VM ip
boot2docker ip

```

## PgModeler

### Build my own pgmodeler container

#### Create a Dockerfile

```
# create dockerfile
mkdir pgmodeler
cd pgmodeler/
touch Dockerfile
vim Dockerfile

// ...
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

// ...

# create libpq.pc file
touch libpq.pc
vim libpq.pc

// ...
prefix=/usr
libdir=${prefix}/lib/postgresql/[VERSION]/lib
includedir=${prefix}/include/postgresql

Name: LibPQ
Version: 5.0.0
Description: PostgreSQL client library
Requires:
Libs: -L${libdir}/libpq.so -lpq
Cflags: -I${includedir}
// ...

# create a startup script
## NB: this script will only be launched in graphical level 2
## but the container is not booted in this level (% runlevel command => unknown)
touch startup_pgmodeler.sh
vim startup_pgmodeler.sh
 
// ...
#!/bin/bash
cd / && \
    start-pgmodeler.sh    

// ...

```

#### Build the container
docker build -t jtran/pgmodeler:v1 .

// ...
** pgModeler build details ** 
 
  PREFIX        = /usr/local 
  BINDIR        = /usr/local/bin 
  PRIVATEBINDIR = /usr/local/lib/pgmodeler/bin 
  PRIVATELIBDIR = /usr/local/lib/pgmodeler 
  PLUGINSDIR    = /usr/local/lib/pgmodeler/plugins 
  SHAREDIR      = /usr/local/share/pgmodeler 
  CONFDIR       = /usr/local/share/pgmodeler/conf 
  DOCDIR        = /usr/local/share/pgmodeler 
  LANGDIR       = /usr/local/share/pgmodeler/lang 
  SAMPLESDIR    = /usr/local/share/pgmodeler/samples 
  SCHEMASDIR    = /usr/local/share/pgmodeler/schemas 
 
* To change a variable value run qmake again setting the desired value e.g.: 
  > qmake PREFIX+=/usr/local -r pgmodeler.pro 
 
* Proceed with build process by running: 
  >  make && make install 
// ...
Successfully built 6c157433c22a

// ...

### Run my own pgmodeler container

``` 
# prompt
# > OSX
# $ docker host (boot2docker)
# % container
```

#### Configure the display forwarding from the container to OSX through the docker host VM

##### docker info

```
# images
> docker images
REPOSITORY           TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
jtran/pgmodeler      v1                  6c157433c22a        2 minutes ago       688.7 MB
ubuntu               trusty              91e54dfb1179        6 weeks ago         188.4 MB

# boot2docker VM ip
> boot2docker ip
192.168.59.103

```

##### redirect the display from VM to OSX

Solution 1:

```
# install socat in osx
> brew install socat
 
# configure socat redirection
> socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"

# from another terminal, run pgmodeler container
# IP 192.168.59.3 is the OSX IP in the Virtualbox local net
> docker run -it -e DISPLAY=192.168.59.3:0 jtran/pgmodeler:v1

```

Solution 2:

```
## [alternative: use X11-unix socket](http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/)
## $DISPLAY refers to the X11/XQuartz display on OSX 
> docker run -ti --rm \
       -e DISPLAY=$DISPLAY \
       -v /tmp/.X11-unix:/tmp/.X11-unix \
	jtran/pgmodeler:v1
	

```
