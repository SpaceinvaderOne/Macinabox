# Pull base build image.
FROM alpine:3.12 AS builder

# Install packages.
RUN apk add \
        bash libressl-dev xterm dbus-x11 \
        py3-gobject3 libosinfo libxml2 build-base python3 py3-docutils \
        gtk+3.0-dev vte3 py3-libxml2 spice-gtk gtk-vnc py3-cairo\
        ttf-dejavu gnome-icon-theme dconf intltool grep gettext-dev \
        libvirt-glib py3-urlgrabber py3-ipaddr py3-libvirt \
        py3-requests py3-urllib3 py3-chardet py3-certifi py3-idna \
        perl-dev cdrkit git && \
    apk add openssh-askpass --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
    && rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]*

# Download virt-manager from git and switch to release 3.2.0
RUN git clone https://github.com/virt-manager/virt-manager.git && cd virt-manager && git checkout ddc55c8

# Install virt-manager with script from developer
RUN cd virt-manager && ./setup.py configure --prefix=/usr/local && ./setup.py install --exec-prefix=/usr/local

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12

# Install packages.
RUN apk add \
        py3-libvirt py3-libxml2 py3-ipaddr py3-cairo py3-requests py3-gobject3 py3-pip py3-click --upgrade \
        libosinfo libvirt-glib dbus-x11 gtksourceview4 \
        bash libressl dconf grep cdrkit gtk-vnc vte3 qemu-img rsync p7zip \
        gnome-icon-theme adwaita-icon-theme && \
    apk add py3-configparser --repository http://dl-3.alpinelinux.org/alpine/v3.10/community/ && \
    apk add openssh-askpass py3-argcomplete dmg2img --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
    && rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]* /usr/share/icons/Adwaita/cursors /usr/share/icons/gnome/256x256 && \
    # Virt-manager wants ssh-askpass without "gtk" in the name
    ln -s /usr/lib/ssh/gtk-ssh-askpass /usr/lib/ssh/ssh-askpass
# Copy macinabox files

COPY . /Macinabox		

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/SpaceinvaderOne/Docker-Templates-Unraid/master/spaceinvaderone/docker_icons/Macinabox.png && \
    install_app_icon.sh "$APP_ICON_URL" \
    && rm -rf /var/cache/apk/*
	
COPY machineid_fix.sh /etc/cont-init.d/20-machineid_fix.sh
COPY startapp.sh /startapp.sh

# Copy Virt-Manager from base build image.
COPY --from=builder /usr/local /usr/local


# Set the name of the application.
ENV APP_NAME="Macinabox with VirtManager"






