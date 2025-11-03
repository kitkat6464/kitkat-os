FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

FROM ghcr.io/zirconium-dev/zirconium:latest@sha256:6eff4cd5629c257f07efbb5ce137aa644bb2166913c2eebd9e96f42cfd4bf428

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build.sh

RUN ls -lah /usr/lib/modules

RUN bootc container lint
