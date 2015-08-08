FROM debian:7.8
MAINTAINER Truman Woo <chunan.woo@gmail.com>

# Update apt source && install necessary tools
RUN echo "deb http://mirrors.163.com/debian/ stable main" > /etc/apt/sources.list \
 && echo "deb-src http://mirrors.163.com/debian/ stable main" >> /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y curl
RUN apt-get install -y unzip
RUN apt-get install -y wget

# Install Oracle JRE 8
ENV JAVA_HOME /usr/jdk1.8.0_31

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/8u31-b13/server-jre-8u31-linux-x64.tar.gz" \
    | gunzip \
    | tar x -C /usr/ \
    && ln -s $JAVA_HOME /usr/java \
    && rm -rf $JAVA_HOME/man

ENV PATH ${PATH}:${JAVA_HOME}/bin

# Install Scala & SBT
ENV SCALA_VERSION 2.11.6
ENV SBT_VERSION 0.13.8

# Install Scala
RUN \
  cd /root && \
  curl -o scala-$SCALA_VERSION.tgz http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz && \
  tar -xf scala-$SCALA_VERSION.tgz && \
  rm scala-$SCALA_VERSION.tgz && \
  echo >> /root/.bashrc && \
  echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc


# Install sbt
COPY sbt-launch.jar /usr/local/bin/
COPY sbt /usr/local/bin/

RUN \
  chmod u+x /usr/local/bin/sbt

# Install Takipi

# Getting Java tester
RUN wget https://s3.amazonaws.com/app-takipi-com/chen/scala-boom.jar -O scala-boom.jar

# Installing Takipi via apt-get and setting up key
RUN echo "deb [arch=amd64] http://takipi-deb-repo.s3.amazonaws.com stable main" > /etc/apt/sources.list.d/takipi.list
ENV DEBIAN_FRONTEND noninteractive
RUN wget -O - http://takipi-deb-repo.s3.amazonaws.com/hello@takipi.com.gpg.key | apt-key add -
RUN apt-get update
RUN apt-get install takipi

# Overriding binaries with the Heroku version of Takipi
RUN wget https://s3.amazonaws.com/app-takipi-com/deploy/linux/takipi-latest-heroku.tar.gz -O takipi-heroku.tar.gz
RUN tar zxvf takipi-heroku.tar.gz
RUN mv .takipi takipi
RUN cp -r takipi /opt

ENV PATH $PATH:/opt/takipi/bin
ENV TAKIPI_SERVICE_PARAMS --xmx=180M

RUN /opt/takipi/etc/takipi-setup-secret-key S11083#eUUrZxJP8pwJWxyj#tbC76F1tD06MQEZz9G4p+zXo+2EeY86Ngc9T9yg6wJQ=#0d65

# Running Java process with Takipi agent
CMD java -agentlib:TakipiAgent -jar scala-boom.jar

# Define work directory
WORKDIR /
