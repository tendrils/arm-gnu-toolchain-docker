# stage: install cmake and toolchain
FROM debian:bullseye-slim

ARG cmake_version=3.24.1
ARG cmake_installer=cmake-${cmake_version}-linux-x86_64.sh

ARG arm_toolchain_version=12.2.mpacbti-bet1
ARG arm_toolchain=arm-gnu-toolchain-${arm_toolchain_version}-x86_64-arm-none-eabi
ARG arm_toolchain_archive=${arm_toolchain}.tar.xz

WORKDIR /root
COPY ${arm_toolchain_archive}* .

RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
        wget ca-certificates xz-utils ; \
	rm -rf /var/lib/apt/lists/*

ENV WGETRC /.wgetrc
RUN echo 'hsts=0' >> "$WGETRC"

RUN mkdir /install-stage
RUN set -eux; \
	wget -O ${cmake_installer} "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/${cmake_installer}"; \
	wget -O cmake-checksum.txt "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-SHA-256.txt"; \
	grep linux-x86_64.sh cmake-checksum.txt | sha256sum --strict --check -; \
	sh ./${cmake_installer} --prefix=/install-stage --exclude-subdir --skip-license ; \
	rm cmake-*; 

RUN set -eux; \
    [ -f ${arm_toolchain_archive} ] || wget https://developer.arm.com/-/media/Files/downloads/gnu/${arm_toolchain_version}/binrel/${arm_toolchain_archive} ; \
	[ -f ${arm_toolchain_archive}.sha256asc ] || wget https://developer.arm.com/-/media/Files/downloads/gnu/${arm_toolchain_version}/binrel/${arm_toolchain_archive}.sha256asc ; \
	cat ${arm_toolchain_archive}.sha256asc | sha256sum --strict --check -; \
    tar -xf ${arm_toolchain_archive} ; \
    cp -r ${arm_toolchain}/* /install-stage

# stage: copy cmake and toolchain artifacts, set PATH
FROM debian:bullseye

RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
        make git ca-certificates ; \
	rm -rf /var/lib/apt/lists/*

RUN mkdir /tools
COPY --from=0 /install-stage /tools
ENV PATH="/tools/bin:$PATH"

RUN mkdir /project
WORKDIR /project
