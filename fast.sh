#!/bin/bash

# Get the start timestamp
start_time=$(date +%s)

# 获取所有静态 IP 地址
aws lightsail get-static-ips --query 'staticIps[*].[name]' --output text | while read -r ip_name
do
  # 首先解除实例关联
  instance=$(aws lightsail get-static-ip --static-ip-name $ip_name --query 'staticIp.attachedTo' --output text)
  
  if [ "$instance" != "None" ]; then
    echo "Detaching $ip_name from $instance..."
    aws lightsail detach-static-ip --static-ip-name $ip_name
  fi

  # 如果 IP 存在，则删除
  echo "Deleting $ip_name..."
  aws lightsail release-static-ip --static-ip-name $ip_name
done

# Wait for 5 seconds
sleep 5s

# 获取所有实例名称
instance_names=$(aws lightsail get-instances | jq -r '.instances[] | .name')

# Stop instances
echo "$instance_names" | xargs --no-run-if-empty -P 4  -I {} aws lightsail stop-instance --instance-name {}

# Wait for 30 seconds
sleep 30s

# Start instances
echo "$instance_names" | xargs --no-run-if-empty -P 4  -I {} aws lightsail start-instance --instance-name {}

# Wait for 20 seconds
sleep 20s

# Display instance names and public IP addresses
aws lightsail get-instances --query "instances[*].[name, publicIpAddress]" --output json | jq -r '.[] | @tsv' | sort

# Get the end timestamp
end_time=$(date +%s)

# Calculate the time elapsed
elapsed_time=$(($end_time-$start_time))

echo "Total execution time: $elapsed_time seconds."
