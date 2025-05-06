#!/usr/bin/bash

# Simple test start script

# Start server
./export/linux/bin/NetTennis -s -i 127.0.0.1 -p 5000 &

sleep 5

# Start client
./export/linux/bin/NetTennis -i 127.0.0.1 -p 5000 &
