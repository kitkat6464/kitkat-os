FROM scratch AS ctx

COPY system_files /system_files

COPY desktop.sh /desktop.sh
COPY cleanup /cleanup

FROM ghcr.io/kitkat6464/aloy:latest@sha256:beebcd3964b243a1e87f9f9da3e02a417299d0059d59ed8b2825a0ad8571b949

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
