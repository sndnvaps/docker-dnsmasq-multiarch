ARG DOCKER_PREFIX=i386
ARG ARCHITECTURE=386
# Stage 0: Preparations. To be run on the build host
FROM alpine:latest
ARG ARCHITECTURE
ARG ALPINE_ARCH=x86
# webproc release settings
ARG WEBPROC_VERSION=0.2.2
ARG WEBPROC_URL="https://github.com/jpillora/webproc/releases/download/$WEBPROC_VERSION/webproc_linux_${ARCHITECTURE}.gz"
# fetch webproc binary
RUN wget -O - ${WEBPROC_URL} | gzip -d > /webproc \
	&& chmod 0755 /webproc
# dnsmasq configuration
RUN echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /dnsmasq.default
# FIXME: This is an ugly hack, but can't run apk cross-platform on stage 1
RUN apk update \
	&& wget -O dnsmasq.apk `apk policy dnsmasq | tail -1`/${ALPINE_ARCH}/dnsmasq-`apk policy dnsmasq \
		| sed -e '2!d' -e 's/ *//' -e 's/://'`.apk

# Stage 1: The actual produced image
FROM ${DOCKER_PREFIX}/alpine:latest
LABEL maintainer="Toni Corvera <outlyer@gmail.com>"
ARG ARCHITECTURE
# import webproc binary from previous stage
COPY --from=0 /webproc /usr/local/bin/
# fetch dnsmasq
RUN apk update && apk --no-cache add dnsmasq
# configure dnsmasq
RUN mkdir -p /etc/default/
COPY --from=0 /dnsmasq.default /etc/default/dnsmasq
COPY dnsmasq.conf /etc/dnsmasq.conf

# TODO: 5353/udp?
EXPOSE 80/tcp 67/udp

# run!
ENTRYPOINT ["webproc","--port","80","--config","/etc/dnsmasq.conf","--","dnsmasq","--no-daemon"]
