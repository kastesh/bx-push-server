# push/Dockerfile
FROM node:10

VOLUME /var/log/push-server

RUN mkdir -p /opt/push-server

ADD https://repos.1c-bitrix.ru/yum-testing/push-server-2.0.8.tar.gz /opt/push-server/push-server.tar.gz

WORKDIR /opt/push-server

RUN tar xzvvf push-server.tar.gz && \
    rm -f push-server.tar.gz

RUN npm install --production

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
