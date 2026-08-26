FROM debian:13

ARG ALIRE_VERSION=2.1.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        libopencv-dev \
        pkg-config \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L \
        -o /tmp/alire.zip \
        "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/alr-${ALIRE_VERSION}-bin-x86_64-linux.zip" \
    && unzip /tmp/alire.zip -d /tmp/alire \
    && install -m 0755 /tmp/alire/bin/alr /usr/local/bin/alr \
    && rm -rf /tmp/alire /tmp/alire.zip

RUN alr -n --force toolchain --select \
        gnat_native=16.1.0 \
        gprbuild=26.0.1

WORKDIR /workspace

CMD ["/bin/bash"]
