#!/bin/bash
set -eux

export ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
export API_KEY="${API_KEY:-C66QKEUKNJG9A0KYU32I}"
export ICECAST_ADMIN_PASSWORD="${ICECAST_ADMIN_PASSWORD:-admin}"
export ICECAST_ADMIN_USERNAME="${ICECAST_ADMIN_USERNAME:-admin}"
export ICECAST_HOST="${ICECAST_HOST:-icecast}"
export POSTGRES_DB="${POSTGRES_DB:-airtime}"
export POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-airtime}"
export POSTGRES_USER="${POSTGRES_USER:-airtime}"
export RABBITMQ_HOST="${RABBITMQ_HOST:-rabbitmq}"
export RABBITMQ_PASS="${RABBITMQ_PASS:-airtime}"
export RABBITMQ_USER="${RABBITMQ_USER:-airtime}"
export RABBITMQ_VHOST="${RABBITMQ_VHOST:-/airtime}"

export PGDATABASE=${POSTGRES_DB}
export PGHOST=${POSTGRES_HOST}
export PGPASSWORD=${POSTGRES_PASSWORD}
export PGUSER=${POSTGRES_USER}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- supervisord "$@"
fi

database_empty () {
  psql -x -c "SELECT COUNT(*) FROM cc_subjs;" && return 1 || return 0
}

fix_permissions () {
  chown -R www-data:www-data /srv/airtime
}

init_database () {
  psql -f /usr/share/airtime/build/sql/schema.sql
  psql -f /usr/share/airtime/build/sql/sequences.sql
  psql -f /usr/share/airtime/build/sql/views.sql
  psql -f /usr/share/airtime/build/sql/triggers.sql
  psql -f /usr/share/airtime/build/sql/defaultdata.sql

  psql -c "INSERT INTO cc_music_dirs("directory", "type") VALUES('/srv/airtime/stor/', 'stor');"
}

set_admin_password () {
  psql -c "UPDATE cc_subjs SET "pass"=md5('${ADMIN_PASSWORD}') WHERE "login"='admin';"
}

set_airtime_config () {
  envsubst < /etc/airtime/airtime.conf.tmpl > /etc/airtime/airtime.conf

  airtime-update-db-settings
}

set_icecast_settings () {
  psql -c "UPDATE cc_stream_setting SET "value"='${ICECAST_ADMIN_PASSWORD}' WHERE "keyname"='s1_admin_pass';"
  psql -c "UPDATE cc_stream_setting SET "value"='${ICECAST_ADMIN_USERNAME}' WHERE "keyname"='s1_admin_user';"
  psql -c "UPDATE cc_stream_setting SET "value"='${ICECAST_HOST}' WHERE "keyname"='s1_host';"
}

if [ "${1}" = "supervisord" ]; then
  if database_empty; then
    init_database
  fi

  fix_permissions
  set_admin_password
  set_airtime_config
  set_icecast_settings
fi

exec "$@"
