#!/bin/bash
set -e

exec "/usr/sbin/nginx" -c $nginx_conf -g "daemon off;"