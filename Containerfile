FROM scratch AS ctx

COPY system_files /system_files

COPY desktop.sh /desktop.sh
COPY cleanup /cleanup

FROM ghcr.io/kitkat6464/aloy:latest@sha256:423e83c8cf025b8902b76d9ae6ed8e5b8561d69d778d087fe14624258c635ad6

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
