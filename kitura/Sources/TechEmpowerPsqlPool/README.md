# Initial Setup

### Install Postgres

```
apt-get install postgresql
```

### Set up benchmark userid and database

This script from the TechEmpower project will create the `benchmarkdbuser`, and create and populate the `hello_world` database:
```
git clone https://github.com/TechEmpower/FrameworkBenchmarks.git
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
