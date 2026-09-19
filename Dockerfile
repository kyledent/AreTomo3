# AreTomo3 container image.
#
#   docker build -t aretomo3 .
#   docker build -t aretomo3:cuda12 \
#       --build-arg CUDA=12.8.1 --build-arg MAKEFILE=makefile11 .
#
# Run with GPU access, e.g.
#   docker run --gpus all -v "$PWD":/data -w /data aretomo3 -InPrefix ...
#   apptainer run --nv docker://ghcr.io/<owner>/aretomo3:<tag> ...

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
 && make -f ${MAKEFILE} exe CUDAHOME=/usr/local/cuda

FROM nvidia/cuda:${CUDA}-runtime-${UBUNTU}
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libtiff6 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/AreTomo3 /usr/local/bin/AreTomo3
COPY LICENSE.md /usr/share/doc/aretomo3/LICENSE.md
LABEL org.opencontainers.image.title="AreTomo3" \
      org.opencontainers.image.licenses="BSD-3-Clause"
ENTRYPOINT ["/usr/local/bin/AreTomo3"]
