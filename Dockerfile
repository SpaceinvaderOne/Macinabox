# Base image
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

ENV SLEEPTIME=60

# Install required packages
RUN apt-get update && \
    apt-get install -y avahi-daemon bash curl unzip qemu-utils sed libvirt-daemon gawk util-linux sshpass coreutils iputils-ping xz-utils uuid-runtime libvirt-clients \
    rsync qemu uml-utilities libguestfs-tools p7zip-full jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the files into the container
COPY . /app

# Set permissions
RUN chmod -R 777 /app

# Set entrypoint
ENTRYPOINT ["/app/letsgo.sh"]