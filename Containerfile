FROM scratch AS ctx

COPY system_files /system_files

COPY desktop.sh /desktop.sh
COPY cleanup /cleanup

FROM ghcr.io/kitkat6464/aloy:latest@sha256:dde96d3809ba8bd6776061463c7ef8253269566cbbb601982b8b74029bb839fa

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
