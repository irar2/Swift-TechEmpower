This project contains a number of targets:

- `TechEmpower`: only implements test 6 (plaintext) and is intended for basic performance sanity testing. This target does not require a database and can be driven via the `/plaintext` URI.
- `HelloLogging`: same plaintext test, but with logging enabled using `HeliumLogger` at the `.info` level. Intended to track the overheads of enabling logging at a level that would be used in production.
- `HelloVerbose`: same plaintext test, but with logging at the `.verbose` level. Generates more significant log activity, intended to track the performance of the logger.
- `TechEmpowerPsqlPool`: a work-in-progress implementation of the TechEmpower benchmarks on Kitura. It currently implements all benchmarks except for test 4 (Fortunes). It uses the Postgres database. There is currently no ORM support.

The `TechEmpowerPsqlPool` target requires a database, for which you can follow the steps below.

# Initial Setup

### Install Postgres

```
apt-get install postgresql
```

### Clone the TechEmpower FrameworkBenchmarks project

```
git clone https://github.com/TechEmpower/FrameworkBenchmarks.git
```

### Create the hello_world database

After this point, you can use the provided `postgres_ramdisk.sh` script to set everything up a ramdisk for you (usage: `postgres_ramdisk.sh start | stop | status`).  Make sure to read the comments at the top of the script first and customize if required.

Alternatively, follow the steps below:

### Set up benchmark userid and database

This script from the TechEmpower project will create the `benchmarkdbuser`, and create and populate the `hello_world` database:
```
cd FrameworkBenchmarks/config
sudo su - postgres -c "psql -f $PWD/create-postgres-database.sql"
psql -U benchmarkdbuser -f create-postgres.sql hello_world
```

### Set up remote access (optional)

To allow remote connections from the benchmark DB user, edit `/etc/postgresql/xx/main/pg_hba.conf`
Add an entry to enable access from a specific host or subnet, for example:

```
# host  DATABASE     USER             ADDRESS         METHOD      [OPTIONS]
host    hello_world  benchmarkdbuser  192.168.0.0/24  password
```

# Driving Benchmark

In separate terminal windows:
```
env DB_HOST="localhost" DB_PORT="5432" .build/release/TechEmpowerPsqlPool
wrk -c128 -t16 -d30s http://127.0.0.1:8080/db
```
