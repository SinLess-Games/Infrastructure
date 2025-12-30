FROM alpine:3.20
RUN apk add --no-cache tftp-hpa
EXPOSE 69/udp
ENTRYPOINT ["in.tftpd","--foreground","--listen","--address","0.0.0.0:69","--secure","/srv/tftp"]
