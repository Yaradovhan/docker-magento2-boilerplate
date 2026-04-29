#!/bin/sh
envsubst '${DOMAIN}' < /etc/msmtprc.template > /etc/msmtprc
exec "$@"
