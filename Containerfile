FROM scratch AS ctx

COPY system_files /system_files

COPY desktop.sh /desktop.sh
COPY cleanup /cleanup

FROM ghcr.io/kitkat6464/aloy:latest@sha256:69dc4e045d2097941308176f33d67139435aed3217e9f17db637b43c8261e6b5

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/desktop.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/cleanup

RUN bootc container lint
