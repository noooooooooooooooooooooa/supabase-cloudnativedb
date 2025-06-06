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

# MINIMAL APPROACH: Install extension without adding PostgreSQL APT repo
# This avoids version conflicts entirely
RUN set -xe; \
	apt-get update; \
	# Try to install pg-failover-slots from existing repos first
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pg-failover-slots" \
	|| ( \
		echo "Package not found in existing repos, adding PostgreSQL APT repo..."; \
		apt-get install -y postgresql-common; \
		/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y; \
		apt-get update; \
		# Hold core packages before installing extension
		apt-mark hold postgresql-${PG_MAJOR} postgresql-client-${PG_MAJOR}; \
		apt-get install -y --no-install-recommends \
			"postgresql-${PG_MAJOR}-pg-failover-slots" \
	); \
	echo "=== PostgreSQL version check ==="; \
	postgres --version; \
	pg_dump --version; \
	echo "=== Cleanup ==="; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install barman-cloud
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		build-essential python3-dev libsnappy-dev \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install  --upgrade pip; \
	pip3 install  --no-deps -r requirements.txt; \
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
    echo "=== End Version Check ==="
