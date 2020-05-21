#!/bin/bash

LOG=/var/log/redis

chown -R redis:redis /var/log/redis

redis-server /usr/local/etc/redis/redis.conf
