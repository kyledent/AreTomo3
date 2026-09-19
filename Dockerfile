# AreTomo3 container image.
#
#   docker build -t aretomo3:cuda13 .
#   docker build -t aretomo3:cuda12 \
#       --build-arg CUDA=12.8.1 --build-arg MAKEFILE=makefile11 .
#
# The CUDA 13 image needs an NVIDIA driver of version 580 or newer; use the
# CUDA 12 image on hosts with older drivers.
#
# Run with GPU access:
#   docker run --gpus all -v "$PWD":/data -w /data aretomo3:cuda13 AreTomo3 -InPrefix ...
#   apptainer exec --nv docker://ghcr.io/<owner>/aretomo3:<tag>-cuda13 AreTomo3 ...
#
# The image has no ENTRYPOINT, so workflow engines can run their own command
# line in it; AreTomo3 is on PATH. /opt/aretomo3/BUILD_COMMIT records the
# commit the binary was built from.

ARG CUDA=13.0.2
ARG UBUNTU=ubuntu24.04

FROM nvidia/cuda:${CUDA}-devel-${UBUNTU} AS build
ARG MAKEFILE=makefile13
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      make g++ libtiff-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN make -C LibSrc/Util \
 && make -C LibSrc/Mrcfile \
 && make -f ${MAKEFILE} cuda -j"$(nproc)" CUDAHOME=/usr/local/cuda \
 && make -f ${MAKEFILE} compile -j"$(nproc)" CUDAHOME=/usr/local/cuda \
 && make -f ${MAKEFILE} exe CUDAHOME=/usr/local/cuda \
 && /usr/local/cuda/bin/cuobjdump --list-elf AreTomo3 \
      | sed -n 's/.*\.\(sm_[0-9]*\)\..*/\1/p' | sort -u > /src/ARCHITECTURES

FROM nvidia/cuda:${CUDA}-runtime-${UBUNTU}
ARG CUDA
ARG MAKEFILE=makefile13
ARG BUILD_COMMIT=unknown
# procps provides ps, which workflow engines use to monitor tasks.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libtiff6 procps \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/AreTomo3 /usr/local/bin/AreTomo3
COPY --from=build /src/ARCHITECTURES /opt/aretomo3/ARCHITECTURES
COPY LICENSE.md /usr/share/doc/aretomo3/LICENSE.md
RUN printf '%s\n' "${BUILD_COMMIT}" > /opt/aretomo3/BUILD_COMMIT \
 && printf 'CUDA %s, %s\n' "${CUDA}" "${MAKEFILE}" > /opt/aretomo3/BUILD_INFO
LABEL org.opencontainers.image.title="AreTomo3" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.revision="${BUILD_COMMIT}"
CMD ["AreTomo3", "--version"]
