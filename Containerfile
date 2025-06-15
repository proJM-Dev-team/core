FROM docker.io/library/archlinux:base-devel AS pacstrap

ARG ARCHIVE_DATE=week
ARG ARCHIVE_SERVER=https://archive.archlinux.org/repos

RUN pacman-key --init
RUN pacman -Sy --needed --noconfirm archlinux-keyring arch-install-scripts

RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
RUN pacman-key --lsign-key 3056513887B78AEB

RUN pacman-key --recv-key D6C9442437365605 --keyserver keyserver.ubuntu.com
RUN pacman-key --lsign-key D6C9442437365605

RUN pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
RUN pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

RUN pacman-key --recv-key  D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B
RUN pacman-key --lsign-key D6D6FAA25E9A3E4ECD9FBDBEC93AF1698685AD8B

WORKDIR /

COPY pacstrap-docker /usr/bin
RUN <<EOF cat > /etc/pacman.conf
[options]
Architecture = auto
ParallelDownloads = 2
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Never

[core]
Server = $ARCHIVE_SERVER/$ARCHIVE_DATE/core/os/\$arch

[extra]
Server = $ARCHIVE_SERVER/$ARCHIVE_DATE/extra/os/\$arch

[multilib]
Server = $ARCHIVE_SERVER/$ARCHIVE_DATE/multilib/os/\$arch

[chaotic-aur]
Server = https://cdn-mirror.chaotic.cx/chaotic-aur/\$arch

[trinity]
Server = https://mirror.ppa.trinitydesktop.org/trinity/archlinux/\$arch
EOF

#RUN sed -i "s|ARCHIVE_SERVER|$ARCHIVE_SERVER|g" /etc/pacman.conf
#RUN sed -i "s|ARCHIVE_DATE|$ARCHIVE_DATE|g" /etc/pacman.conf
RUN cat /etc/pacman.conf

RUN rm -rf /rootfs; mkdir /rootfs
RUN pacstrap-docker /rootfs base

FROM scratch as root

COPY --from=pacstrap /rootfs/ /

LABEL supports-commonarch="true" \
      name="CommonArch Base Image" \
      usage="This image is meant to be used on CommonArch" \
      summary="Base image for creating CommonArch Desktop images" \
      maintainer="proJM-Coding <81658610+proJM-Coding@users.noreply.github.co>"

# Install extra packages
COPY extra-packages /
RUN pacman -Syu --needed --noconfirm - < extra-packages
RUN rm /extra-packages

# Install and enable networkmanager and bluez
RUN pacman -Syu --needed --noconfirm networkmanager bluez
RUN systemctl enable NetworkManager; systemctl enable bluetooth

# Clean up cache
RUN yes | pacman -Scc

# Enable sudo permission for wheel users
RUN echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
