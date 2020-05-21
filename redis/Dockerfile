FROM redis

VOLUME /var/log/redis

RUN mkdir /usr/local/etc/redis -p

ADD etc/redis.conf /usr/local/etc/redis/redis.conf
 
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chown root:redis /usr/local/etc/redis/redis.conf && \
    chmod 0755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 6379

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
