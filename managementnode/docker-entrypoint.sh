#!/bin/bash
set -e
USER_ID=${LOCAL_USER_ID:-9001}
echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m standarduser
export HOME=/home/standarduser

echo "[Entrypoint] VCL Management Daemon"

# Update VCL Configuration File
echo "[Entrypoint] Updating vcl daemon configuration file /etc/vcl/vcld.conf"
echo "updating FQDN to $HOSTNAME"
sed -i "s/^\(FQDN=\).*/\1$HOSTNAME/" /etc/vcl/vcld.conf
echo "updating database name to $MYSQL_DATABASE"
sed -i "s/^\(database=\).*/\1${MYSQL_DATABASE//\//\\/}/" /etc/vcl/vcld.conf
echo "updating database host to $DB_HOST"
sed -i "s/^\(server=\).*/\1${DB_HOST//\//\\/}/" /etc/vcl/vcld.conf
echo "updating database user to $MYSQL_USER"
sed -i "s/^\(LockerWrtUser=\).*/\1${MYSQL_USER//\//\\/}/" /etc/vcl/vcld.conf
echo "updating database user password to $MYSQL_PASSWORD"
sed -i "s/^\(wrtPass=\).*/\1${MYSQL_PASSWORD//\//\\/}/" /etc/vcl/vcld.conf
echo "updating log file to /var/log/vcl/vcld-${HOSTNAME}.log"
sed -i "s/^\(log=\).*/\1\/var\/log\/vcl\/vcld-${HOSTNAME}.log/" /etc/vcl/vcld.conf
echo "updating xmlrpc user password to $XMLRPC_PASSWORD"
sed -i "s/^\(xmlrpc_pass=\).*/\1${XMLRPC_PASSWORD//\//\\/}/" /etc/vcl/vcld.conf
echo "updating xmlrpc user to $XMLRPC_USER"
sed -i "s/^\(xmlrpc_username=\).*/\1${XMLRPC_USER//\//\\/}/" /etc/vcl/vcld.conf
echo "updating xmlrpc url to $XMLRPC_URL"
sed -i "s/^\(xmlrpc_url=\).*/\1${XMLRPC_URL//\//\\/}/" /etc/vcl/vcld.conf
echo "updating windows root password to $WINDOWS_ROOT_PASSWORD"
sed -i "s/^\(WINDOWS_ROOT_PASSWORD=\).*/\1${WINDOWS_ROOT_PASSWORD//\//\\/}/" /etc/vcl/vcld.conf

echo "[Entrypoint] VCL configuration file post-update"
cat /etc/vcl/vcld.conf

# Update database
echo "[Entrypoint] Updating management node information in database"
perl -f /configure-vcl-db.pl

# Configure Postfix MTA
echo "[Entrypoint] Updating postfix configuration"
postconf -e inet_interfaces=all
postconf -e relayhost=${SMTP_RELAY_HOST}:${SMTP_RELAY_PORT}
postconf -e myhostname=${SMTP_MYHOSTNAME}

# Start VCL Daemon
echo "[Entrypoint] Starting VCL Daemon using $@"
exec "$@"
