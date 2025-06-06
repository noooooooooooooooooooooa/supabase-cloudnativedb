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

# CRITICAL: Do NOT add the PostgreSQL APT repository to avoid version conflicts
# The base Supabase image already has all PostgreSQL binaries at the correct version

# Verify PostgreSQL versions are consistent (all should be 17.4)
RUN echo "=== Base Image PostgreSQL Versions ===" && \
    postgres --version && \
    pg_dump --version && \
    pg_ctl --version && \
    pg_upgrade --version && \
    echo "=== All versions should show 17.4 ==="

# Install barman-cloud (without touching PostgreSQL packages)
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

# Final version verification - ensure no version drift occurred
RUN echo "=== Final PostgreSQL Version Check ===" && \
    postgres --version && \
    pg_dump --version && \
    pg_ctl --version && \
    pg_upgrade --version && \
    echo "=== All should still be PostgreSQL 17.4 ==="

# Change the uid of postgres to 26
# not needed, we use the one from supabase (101:102)
# RUN usermod -u 26 postgres
# USER 26
