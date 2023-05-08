FROM nginx:1.23.4-alpine3.17

LABEL org.opencontainers.image.source https://github.com/theshamuel/nginx-ssl

ENV LEGO_VERSION="4.11.0"

ADD etc/nginx.conf /etc/nginx/nginx.conf
ADD etc/entrypoint.sh /entrypoint.sh

RUN apk add --no-cache --update ca-certificates tzdata openssl libc-dev && \
    cd /tmp && \
    curl -Lko /tmp/lego.tar.gz https://github.com/xenolf/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_linux_amd64.tar.gz && \
    tar -xf /tmp/lego.tar.gz -C /usr/bin/ && \
    RED='\e[32m'; NO_COLOR='\e[39m'; echo -e "${RED}--->$(lego -version)${NO_COLOR}" && \
    chmod +x /entrypoint.sh

RUN  rm -rf /etc/nginx/conf.d/*

RUN  rm -rf /var/cache/apk/*

CMD ["/entrypoint.sh"]
