# vim:set ft=dockerfile:
FROM ubuntu:14.04
MAINTAINER Luca Botti <lnospambottithanks@red.software.systems>


ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget


# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN locale-gen en_US.UTF-8

ENV PG_VERSION 9.3

# Install Postgres & Postgis
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-9.3 postgresql-9.3-postgis-2.1 \
postgresql-9.3-postgis-scripts postgresql-client-9.3 postgresql-client-common postgresql-common \
postgresql-contrib-9.3 postgis* postgresql-9.3-postgis-2.1 postgresql-9.3-postgis-scripts libpq-dev python-psycopg2


RUN pg_dropcluster $PG_VERSION main && pg_createcluster --locale en_US.UTF-8 $PG_VERSION main

RUN echo "host    all             all             0.0.0.0/0 trust" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/$PG_VERSION/main/postgresql.conf

#USER postgres



#ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
#ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/

COPY start-db-postgis.sh /

RUN ["chmod", "+x", "/start-db-postgis.sh"]

RUN service postgresql start && /start-db-postgis.sh && service postgresql stop


EXPOSE 5432
CMD ["su", "postgres", "-c", "/usr/lib/postgresql/$PG_VERSION/bin/postgres -D /var/lib/postgresql/$PG_VERSION/main/ -c config_file=/etc/postgresql/$PG_VERSION/main/postgresql.conf"]

#USER postgres
#ENTRYPOINT ["/start-db-postgis.sh"]
