FROM debian:12

ARG ALIRE_VERSION=2.1.1
ARG OPENCV_VERSION=4.1.0

ENV DEBIAN_FRONTEND=noninteractive

# Development tools installed through Alire live here.
ENV PATH="/opt/alire-tools/bin:${PATH}"

# OpenCV is installed from source under /usr/local.
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig"
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib/x86_64-linux-gnu"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        file \
        git \
        jq \
        less \
        ninja-build \
        pkg-config \
        procps \
        python3 \
        ripgrep \
        unzip \
    && rm -rf /var/lib/apt/lists/*

#
# Alire 2.1.1
#
RUN curl -L \
        -o /tmp/alire.zip \
        "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/alr-${ALIRE_VERSION}-bin-x86_64-linux.zip" \
    && unzip /tmp/alire.zip -d /tmp/alire \
    && install -m 0755 /tmp/alire/bin/alr /usr/local/bin/alr \
    && rm -rf /tmp/alire /tmp/alire.zip

#
# Ada toolchain
#
RUN alr -n --force toolchain --select \
        gnat_native=16.1.0 \
        gprbuild=26.0.1

#
# GNATformat for Cline/development use.
#
# Use a fixed prefix because the development container is normally
# launched with HOME=/tmp.
#
RUN mkdir -p /opt/alire-tools \
    && alr install --prefix=/opt/alire-tools gnatformat_bin

#
# Build exactly OpenCV 4.1.0 from source.
#
# Only OpenCV Core is required. Disable unnecessary modules and old
# bundled dependencies that are problematic with modern compilers.
#
RUN curl -L \
        -o /tmp/opencv.tar.gz \
        "https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.tar.gz" \
    && mkdir -p /tmp/opencv-src \
    && tar -xzf /tmp/opencv.tar.gz \
        --strip-components=1 \
        -C /tmp/opencv-src \
    && cmake \
        -S /tmp/opencv-src \
        -B /tmp/opencv-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_CXX_STANDARD=11 \
        -DBUILD_LIST=core \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_opencv_apps=OFF \
        -DBUILD_opencv_dnn=OFF \
        -DBUILD_DOCS=OFF \
        -DBUILD_JAVA=OFF \
        -DBUILD_PACKAGE=OFF \
        -DWITH_PROTOBUF=OFF \
        -DBUILD_PROTOBUF=OFF \
        -DWITH_IPP=OFF \
        -DWITH_OPENCL=OFF \
        -DWITH_LAPACK=OFF \
        -DWITH_EIGEN=OFF \
        -DWITH_TBB=OFF \
        -DWITH_ITT=OFF \
        -DOPENCV_GENERATE_PKGCONFIG=ON \
        -DENABLE_CCACHE=ON \
    && cmake --build /tmp/opencv-build \
    && cmake --install /tmp/opencv-build \
    && rm -rf \
        /tmp/opencv-src \
        /tmp/opencv-build \
        /tmp/opencv.tar.gz

RUN ldconfig

#
# Cline state.
#
# The development container is launched with HOME=/tmp and typically
# bind-mounts skills at /tmp/.cline/skills. Pre-create the parent as
# writable so Podman doesn't create it with unsuitable ownership.
#
RUN mkdir -p /tmp/.cline \
    && chmod 1777 /tmp/.cline

WORKDIR /workspace

CMD ["/bin/bash"]