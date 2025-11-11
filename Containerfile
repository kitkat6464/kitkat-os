FROM scratch AS ctx

COPY desktop.sh /desktop.sh
COPY cleanup /cleanup

FROM ghcr.io/kitkat6464/aloy:latest@sha256:8cbf542c89613f9de61846a0db8d56882113fe8756670017051cfbaf643ac549

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
