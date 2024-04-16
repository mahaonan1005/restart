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


# For each instance in the list, start it using xargs
echo "$instance_names" | xargs --no-run-if-empty -P 4 -I {} bash -c '
  instance="{}"
  echo "Starting instance: $instance"
  
  # Check instance state
  state=$(aws lightsail get-instance-state --instance-name $instance --query '"'state.name'"' --output text)
  
  # If instance is not stopped, wait for it to stop before starting it
  while [ "$state" != "stopped" ]
  do
    echo "Waiting for instance: $instance to stop"
    sleep 5
    state=$(aws lightsail get-instance-state --instance-name $instance --query '"'state.name'"' --output text)
  done
  
  # Start instance
  aws lightsail start-instance --instance-name $instance
'


# Wait for 5 seconds
sleep 5s

# 获取所有实例名称
instance_names=$(aws lightsail get-instances | jq -r '.instances[] | .name')


# Display instance names and public IP addresses
aws lightsail get-instances --query "instances[*].[name, publicIpAddress]" --output json | jq -r '.[] | @tsv' | sort

# Get the end timestamp
end_time=$(date +%s)

# Calculate the time elapsed
elapsed_time=$(($end_time-$start_time))

echo "Total execution time: $elapsed_time seconds."
