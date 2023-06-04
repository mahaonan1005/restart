#!/bin/bash

# 记录脚本开始运行的时间
start=$(date +%s)

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

# 获取所有实例名称
instance_names=$(aws lightsail get-instances | jq -r '.instances[] | .name')

# Stop instances
echo "$instance_names" | xargs --no-run-if-empty -P 4 -I {} aws lightsail stop-instance --instance-name {}

# Wait for instances to stop
for name in $instance_names; do
  while :
  do
    status=$(aws lightsail get-instance-state --instance-name "$name" --query 'state.name' --output text)
    if [ "$status" == "stopped" ]; then
      echo "Instance $name has stopped"
      break
    else
      echo "Waiting for instance $name to stop..."
      sleep 5
    fi
  done
done

# Start instances
echo "$instance_names" | xargs --no-run-if-empty -P 4 -I {} aws lightsail start-instance --instance-name {}

# Wait for instances to start
for name in $instance_names; do
  while :
  do
    status=$(aws lightsail get-instance-state --instance-name "$name" --query 'state.name' --output text)
    if [ "$status" == "running" ]; then
      echo "Instance $name has started"
      break
    else
      echo "Waiting for instance $name to start..."
      sleep 5
    fi
  done
done

# Display instance names and public IP addresses
aws lightsail get-instances --query "instances[*].[name, publicIpAddress]" --output json | jq -r '.[] | @tsv' | sort

# 记录脚本结束运行的时间
end=$(date +%s)

# 计算并输出脚本运行的时长
duration=$((end - start))
echo "The script ran for $duration seconds."
