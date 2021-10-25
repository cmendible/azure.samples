# Downlod redis tools
Invoke-WebRequest -Uri "https://github.com/microsoftarchive/redis/releases/download/win-3.2.100/Redis-x64-3.2.100.zip" -OutFile redis.zip -UseBasicParsing
Expand-Archive -Path .\redis.zip -DestinationPath .\redis-cli

$redis_name=$(terraform output redis_name)
$redis_host_name=$(terraform output redis_host_name)
$redis_primary_access_key=$(terraform output redis_primary_access_key)

# Prepare the cache instance with data required for the latency and throughput testing
.\redis-cli\redis-benchmark -h $redis_host_name -a $redis_primary_access_key -t SET -n 10 -d 1024

# To test throughput: Pipelined GET requests with 1k payload:
.\redis-cli\redis-benchmark -h $redis_host_name -a $redis_primary_access_key -t GET -n 1000000 -d 1024 -c 50

# Force failover 
az redis force-reboot --reboot-type PrimaryNode -n $redis_name -g redis-failover