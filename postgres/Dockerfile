FROM postgres:17-bookworm

RUN apt-get update \
  && apt-get install -y pgbackrest busybox-static ca-certificates \
  && rm -rf /var/lib/apt/lists/*