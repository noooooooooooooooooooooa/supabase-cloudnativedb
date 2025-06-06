ARG PG_VERSION
ARG PG_MAJOR
FROM supabase/postgres:${PG_VERSION}
ARG PG_VERSION
ARG PG_MAJOR

# Do not split the description, otherwise we will see a blank space in the labels
LABEL name="PostgreSQL Container Images" \
      vendor="The CloudNativePG Contributors" \
      version="${PG_VERSION}" \
      release="5" \
      summary="PostgreSQL Container images." \
      description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres ${PG_VERSION}."

LABEL org.opencontainers.image.description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres ${PG_VERSION}."

COPY requirements.txt /

ARG DEBIAN_FRONTEND=noninteractive

# Add PostgreSQL APT repository
RUN apt-get update && apt-get install -y postgresql-common && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

# Install additional extensions while preventing PostgreSQL core package upgrades
RUN set -xe; \
	apt-get update; \
	# Hold existing PostgreSQL packages to prevent version upgrades
	apt-mark hold \
		postgresql-${PG_MAJOR} \
		postgresql-client-${PG_MAJOR} \
		postgresql-client-common \
		postgresql-common \
		postgresql-contrib-${PG_MAJOR} \
		postgresql-${PG_MAJOR}-wal2json \
		postgresql-${PG_MAJOR}-postgis-3 \
		postgresql-${PG_MAJOR}-postgis-3-scripts \
		postgresql-${PG_MAJOR}-pgtap \
		postgresql-${PG_MAJOR}-uuid-ossp \
		postgresql-${PG_MAJOR}-hypopg \
		postgresql-${PG_MAJOR}-index-advisor \
		postgresql-${PG_MAJOR}-plan-filter \
		postgresql-${PG_MAJOR}-pg-stat-monitor \
		postgresql-${PG_MAJOR}-pgaudit \
		postgresql-${PG_MAJOR}-pgjwt \
		postgresql-${PG_MAJOR}-pgsql-http \
		postgresql-${PG_MAJOR}-pgvector \
		postgresql-${PG_MAJOR}-plpgsql-check \
		postgresql-${PG_MAJOR}-rum \
		postgresql-${PG_MAJOR}-safeupdate \
		postgresql-${PG_MAJOR}-timescaledb \
		postgresql-${PG_MAJOR}-cron; \
	# Install new extensions (these should be safe as they don't override core binaries)
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pg-failover-slots" \
	; \
	# Verify versions are still correct
	echo "PostgreSQL version check:"; \
	postgres --version; \
	pg_dump --version; \
	pg_upgrade --version || echo "pg_upgrade not available"; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install barman-cloud
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		# We require build dependencies to build snappy 0.6
		# on Python 3.11 or greater.
		# TODO: Remove build deps once barman unpins the snappy version or
		# https://github.com/EnterpriseDB/barman/issues/905 is completed
		build-essential python3-dev libsnappy-dev \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install  --upgrade pip; \
	# TODO: Remove --no-deps once https://github.com/pypa/pip/issues/9644 is solved
	pip3 install  --no-deps -r requirements.txt; \
	# We require build dependencies to build snappy 0.6
	# on Python 3.11 or greater.
	# TODO: Remove build deps once barman unpins the snappy version or
	# https://github.com/EnterpriseDB/barman/issues/905 is completed
	apt-get remove -y --purge --autoremove \
		build-essential \
		python3-dev \
		libsnappy-dev \
	; \
	rm -rf /var/lib/apt/lists/*;

# Final version verification
RUN echo "=== Final PostgreSQL Version Check ===" && \
    postgres --version && \
    pg_dump --version && \
    (pg_upgrade --version || echo "pg_upgrade not in PATH") && \
    echo "=== End Version Check ==="

# Change the uid of postgres to 26
# not needed, we use the one from supabase (101:102)
# RUN usermod -u 26 postgres
# USER 26
