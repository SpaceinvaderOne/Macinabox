FROM spaceinvaderone/ubuntu_base:focal
MAINTAINER SpaceinvaderOne
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install rsync qemu uml-utilities libguestfs-tools p7zip-full  && apt-get clean && rm -rf /var/lib/apt/lists/**
COPY . /Macinabox
VOLUME  /customovmf
VOLUME  /domains
VOLUME  /isos
VOLUME  /userscripts
VOLUME  /conf
WORKDIR /Macinabox
CMD bash /Macinabox/unraid.sh ; sleep 30








