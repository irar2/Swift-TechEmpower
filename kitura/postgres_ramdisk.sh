#!/bin/bash
#
# Script to create a ramdisk and host a Postgres database suitable for running
# the TechEmpower benchmarks.
#
# Prereqs:
# 1) Postgres is installed and PG_BIN var (below) set appropriately
# 2) FrameworkBenchmarks project is checked out in the current directory, ie.
#    git clone https://github.com/TechEmpower/FrameworkBenchmarks.git
# 3) You have permission to sudo (required to mount/umount a ramdisk)
# 
# If you want to access the test database remotely (ie. not localhost), then
# make sure you update the access controls (see below) to include a rule that
# lets your remote server talk to this one.
#

DBNAME="testdb"
PG_BIN="/usr/lib/postgresql/9.5/bin"
MOUNTPOINT="$HOME/ramdisk_${DBNAME}"
MOUNTPOINT_TMPFS="${MOUNTPOINT}_tmpfs"
DB_DIR="${MOUNTPOINT}/${DBNAME}"
SOCKET_DIR="${MOUNTPOINT}/var/run/postgresql"
DB_PORT=5433

function start {
  # Create ramdisk
  mkdir -p ${MOUNTPOINT} ${MOUNTPOINT_TMPFS}
  sudo mount -t tmpfs -o size=2054M ${DBNAME} ${MOUNTPOINT_TMPFS}
  dd if=/dev/zero of=${MOUNTPOINT_TMPFS}/ramdisk.img bs=4096 count=524288
  mke2fs -F -m 0 -b 4096 -L ext2_${DBNAME} ${MOUNTPOINT_TMPFS}/ramdisk.img 524288
  sudo mount ${MOUNTPOINT_TMPFS}/ramdisk.img ${MOUNTPOINT} -t ext2 -o loop
  if [ $? != 0 ]; then
    echo "Error creating ramdisk"
    return
  fi
  sudo chmod 777 ${MOUNTPOINT}

  # Create database
  mkdir ${DB_DIR}
  ${PG_BIN}/initdb ${DB_DIR}

  # Update access controls
  echo "local   all             all                                     password
host    hello_world     benchmarkdbuser 9.0.0.0/8               password
host    hello_world     benchmarkdbuser 192.168.1.0/24          password
host    hello_world     benchmarkdbuser 192.168.0.0/24          password
" >> ${DB_DIR}/pg_hba.conf

  echo "listen_addresses = '*' 
port = ${DB_PORT}
unix_socket_directories = '${SOCKET_DIR}'
" >> ${DB_DIR}/postgresql.conf
  mkdir -p ${SOCKET_DIR}

  ${PG_BIN}/pg_ctl -D ${DB_DIR} -l ${MOUNTPOINT}/logfile start

  # Generate content
  psql -h ${SOCKET_DIR} -p ${DB_PORT} -d postgres -f $PWD/FrameworkBenchmarks/config/create-postgres-database.sql
  psql -h ${SOCKET_DIR} -p ${DB_PORT} -U benchmarkdbuser -f $PWD/FrameworkBenchmarks/config/create-postgres.sql hello_world
}

function stop {
  ${PG_BIN}/pg_ctl -D ${DB_DIR} -l ${MOUNTPOINT}/logfile stop
  if [ $? -ne 0 ]; then
    echo "Error - postgres server did not shut down"
  fi
  sudo umount ${MOUNTPOINT} ${MOUNTPOINT_TMPFS}
  if [ $? -ne 0 ]; then
    echo "Error - could not unmount ramdisk"
  fi
}

function status {
  psql -w -h ${SOCKET_DIR} -p ${DB_PORT} --list
  if [ $? -eq 0 ]; then
    echo "Ramdisk server is running"
  else
    echo "Ramdisk server appears not to be running"
  fi
}

case "$1" in
start)
  start
  ;;
stop)
  stop
  ;;
status)
  status
  ;;
*)
  echo "Usage: $0 start | stop | status"
esac

