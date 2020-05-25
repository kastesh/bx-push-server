#!/bin/bash

test "$1" = "deploy_cert" || exit 0

nginx -s reload
