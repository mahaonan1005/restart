#!/bin/bash

# Stop instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail stop-instance --instance-name {}

# Wait for 1 minute
sleep 1m

# Start instances
aws lightsail get-instances | jq -r '.instances[] | .name' | xargs -I {} aws lightsail start-instance --instance-name {}
