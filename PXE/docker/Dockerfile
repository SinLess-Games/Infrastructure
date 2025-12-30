FROM alpine:3.20

RUN apk add --no-cache dnsmasq

# dnsmasq writes leases unless you tell it not to; keep it on a writable mount
RUN mkdir -p /var/lib/misc /tftp

# Run dnsmasq in the foreground (PID 1)
ENTRYPOINT ["dnsmasq", "-k"]
