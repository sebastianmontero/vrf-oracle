FROM ubuntu:18.04
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN mkdir /vrf-oracle-code
# WORKDIR /vrf-oracle-code
RUN apt update
RUN apt install apt-utils curl build-essential -y
RUN curl -O https://dl.google.com/go/go1.15.8.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.15.8.linux-amd64.tar.gz
COPY . /vrf-oracle-code
RUN tar -C /usr/local -xzf go1.15.8.linux-amd64.tar.gz
WORKDIR /vrf-oracle-code/core/oracles/vrf
RUN /usr/local/go/bin/go install
