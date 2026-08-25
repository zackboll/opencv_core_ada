FROM debian:13

ARG ALIRE_VERSION=2.1.1
ARG OPENCV_VERSION=5.0.0

ENV DEBIAN_FRONTEND=noninteractive

# Development tools installed through Alire live here.
ENV PATH="/opt/alire-tools/bin:${PATH}"

# OpenCV is installed under /usr/local.
# Include the common multiarch pkg-config/library locations as well.
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
        gnat \
        gprbuild \
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
# GNATformat for Cline/development use.
#
# Use a fixed prefix rather than ~/.alire/bin because the development
# container is normally launched with HOME=/tmp.
#
RUN mkdir -p /opt/alire-tools \
    && alr install --prefix=/opt/alire-tools gnatformat_bin

#
# Build exactly OpenCV 5.0.0 from source.
#
# Only Core is required by opencv_core_ada, so avoid building all of
# OpenCV and its optional modules.
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
        -DCMAKE_CXX_STANDARD=17 \
        -DBUILD_LIST=core \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_opencv_apps=OFF \
        -DBUILD_opencv_python3=OFF \
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
# When skills are bind-mounted at /tmp/.cline/skills, Podman must not
# create the parent directory as root-owned and unwritable by the
# --userns=keep-id development user.
#
RUN mkdir -p /tmp/.cline \
    && chmod 1777 /tmp/.cline

WORKDIR /workspace

CMD ["/bin/bash"]
