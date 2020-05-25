FROM nginx

RUN apt-get update
RUN apt-get install -y vim procps net-tools iproute2
RUN apt-get install -y dehydrated cron

ADD etc/ /etc/nginx/

VOLUME /var/log/nginx

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

RUN rm -rf /etc/cron.weekly /etc/cron.monthly /etc/cron.d /etc/cron.hourly
COPY crontab /etc/crontab
COPY hook.sh /etc/dehydrated/hook.sh

EXPOSE 80/tcp
EXPOSE 443/tcp

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["nginx"]
