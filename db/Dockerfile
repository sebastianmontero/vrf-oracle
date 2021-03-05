FROM postgres:latest
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN mkdir /vrf-db
COPY vrf-db.sql /vrf-db
COPY setup.sh /docker-entrypoint-initdb.d