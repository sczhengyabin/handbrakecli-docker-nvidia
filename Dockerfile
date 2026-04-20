FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

RUN apt-get update && apt-get install -y \
    autoconf automake build-essential cmake git \
    libass-dev libbz2-dev libfontconfig-dev libfreetype-dev \
    libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev \
    libmp3lame-dev libnuma-dev libogg-dev libopus-dev \
    libsamplerate0-dev libspeex-dev libtheora-dev libtool libtool-bin \
    libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev \
    m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev \
    curl libssl-dev clang ca-certificates libva-dev libdrm-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth=1 https://github.com/HandBrake/HandBrake.git

WORKDIR /opt/HandBrake
RUN ./configure --launch-jobs=$(nproc) --launch --disable-gtk --enable-nvdec –enable-qsv

WORKDIR /work
ENTRYPOINT ["/opt/HandBrake/build/HandBrakeCLI"]
