#!/bin/bash

# Stop instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail stop-instance --instance-name {}

# Wait for 30 seconds
sleep 30s

# Start instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail start-instance --instance-name {}
