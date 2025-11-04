FROM scratch AS ctx
COPY build.sh /build.sh
COPY system_files /system_files

FROM ghcr.io/zirconium-dev/zirconium:latest@sha256:33baa6fc3068f155d49571b2ce4e35fa3ef640e9bf73b84352228ffdf1e8e4d2

# Custom Stuff
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN ls -lah /usr/lib/modules

RUN bootc container lint
