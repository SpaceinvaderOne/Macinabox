FROM ubuntu:latest
MAINTAINER SpaceinvaderOne
RUN apt-get update && apt-get -y install qemu git python python-pip bash rsync
COPY . /Macinabox
VOLUME /config
VOLUME /image
VOLUME /xml
CMD ./Macinabox/unraid.sh $flavour $vminstall || : && bash && tail -f /dev/null

