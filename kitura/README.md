This project contains a number of targets:

- `TechEmpower`: only implements test 6 (plaintext) and is intended for basic performance sanity testing. This target does not require a database and can be driven via the `http://localhost:8080/plaintext` URL.
- `HelloLogging`: same plaintext test, but with logging enabled using `HeliumLogger` at the `.info` level. Intended to track the overheads of enabling logging at a level that would be used in production.
- `HelloVerbose`: same plaintext test, but with logging at the `.verbose` level. Generates more significant log activity, intended to track the performance of the logger.
- `HelloSSL`: same plaintext test, but with SSL enabled. The URL for this test is `https://localhost:8080/plaintext`
- `TechEmpowerPsqlPool`: a work-in-progress implementation of the TechEmpower benchmarks on Kitura. It currently implements all benchmarks except for test 4 (Fortunes). It uses the Postgres database. There is currently no ORM support.
- `TechEmpowerKuery`: a work-in-progress implementation of the TechEmpower benchmarks on Kitura using [Swift Kuery](https://github.com/IBM-Swift/Swift-Kuery). It currently implements all benchmarks except for test 4 (Fortunes). There is currently no ORM support. It supports all [plugins supported by Swift Kuery](https://github.com/IBM-Swift/Swift-Kuery#list-of-plugins) which can be switched between using the `DB` environment variable, which defaults to `postgresql`.


The `TechEmpowerPsqlPool` and `TechEmpowerKuery` (with `DB=postgresql`) targets requires a database, for which you can follow the steps below.

# Initial Setup

## Install Postgres

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

## Install workload driver

Install the build dependencies:
```
sudo apt-get install gcc make
```
Clone and build:
```
git clone https://github.com/wg/wrk.git
cd wrk
make
```

This will build the `wrk` tool. You may want to add the wrk executable to your path or to `/usr/local/bin`:
```
sudo cp wrk /usr/local/bin
```

## Install Swiftenv (optional)

Swiftenv makes it easy to obtain the Swift binary which has been tested with this project.
See: https://github.com/kylef/swiftenv

### Install Swift binary

```
swiftenv install
```

## Build Kitura application

Install dependencies:
```
sudo apt-get install clang libicu-dev libcurl4-openssl-dev libssl-dev libpq-dev
```
Either build via the provided `build.sh` script:
```
./build.sh release --clean
```
Or using SPM directly:
```
swift build -c release
```

# Driving Benchmark

In separate terminal windows, start Kitura, and then start the workload driver:
```
env DB_HOST="localhost" DB_PORT="5432" .build/release/TechEmpowerPsqlPool
wrk -c128 -t4 -d30s http://127.0.0.1:8080/db
```
This example exercises the Single Database Query test against the local Postgres database.

## TechEmpower tests

Below are the driver commands which approximate the TechEmpower benchmark suite:

### Test 1 (JSON)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 8 --timeout 8 -t 2 http://127.0.0.1:8080/json
```
This runs the workload driver with 8 concurrent connections (`-c 8`). TechEmpower tests with 8, 16, 32, 64, 128 and 256 connections.

### Test 2 (DB)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 8 --timeout 8 -t 2 http://127.0.0.1:8080/db
```
This runs the workload driver with 8 concurrent connections (`-c 8`). TechEmpower tests with 8, 16, 32, 64, 128 and 256 connections.

### Test 3 (Queries)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/queries?queries=1
```
This runs the workload driver with 256 concurrent connections, and a single DB query per request (`?queries=1`). TechEmpower tests with 1, 5, 10, 15 and 20 queries per request.

### Test 5 (Updates)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/updates?queries=1
```
This runs the workload driver with 256 concurrent connections, and a single DB query/update operation per request (`?queries=1`). TechEmpower tests with 1, 5, 10, 15 and 20 queries per request.

### Test 6 (Plaintext)
```
wrk -H 'Host: localhost' -H 'Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/plaintext -s ~/pipeline.lua -- 16
```
This runs the workload driver with 256 concurrent connections (`-c 256`). TechEmpower tests with 256, 1024, 4096 and 16384 concurrent connections.

Note, TechEmpower uses HTTP Pipelining for the Plaintext test. This is implemented in a LUA script which is created by the script: https://github.com/TechEmpower/FrameworkBenchmarks/blob/master/toolset/setup/linux/client.sh

At the time of writing, Kitura does not properly support HTTP pipelining; either omit the script argument (everything after `-s`) or change the number of requests pipelined (`-- 16`) to `1`.
