#!/bin/bash

# 获取所有静态 IP 地址
ips=$(aws lightsail get-static-ips --query 'staticIps[*].[name]' --output text)

# 保存当前的 IFS 值，以便之后可以恢复
OLDIFS=$IFS
# 设置 IFS 为换行符
IFS=$'\n'

# 遍历每个 IP
for ip_name in $ips
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

# 恢复原来的 IFS 值
IFS=$OLDIFS

# Wait for 5 seconds
sleep 5s

# Stop instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail stop-instance --instance-name {}

# Wait for 45 seconds
sleep 45s

# Start instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail start-instance --instance-name {}

# Wait for 45 seconds
sleep 45s
aws lightsail get-instances --query "instances[*].[name, publicIpAddress]" --output json | jq -r '.[] | @tsv' | sort
