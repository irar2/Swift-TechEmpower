# Initial Setup

git clone https://github.com/TechEmpower/FrameworkBenchmarks.git
cd FrameworkBenchmarks/config
sudo su - postgres -c "psql -f $PWD/create-postgres-database.sql"
psql -U benchmarkdbuser -f create-postgres.sql hello_world

# Driving Benchmark

.build/release/TechEmpowerPsqlPool
wrk -c128 -t16 -d30s http://127.0.0.1:8080/db
