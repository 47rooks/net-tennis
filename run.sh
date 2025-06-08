#!/usr/bin/bash

# Simple test start script

# Start server
./export/linux/bin/NetTennis -s -i 127.0.0.1 -p 5000 &

sleep 5

# Start client with AI player
./export/linux/bin/NetTennis -i 127.0.0.1 -p 5000 -a &


./export/linux/bin/NetTennis -i 127.0.0.1 -p 5000 --p2 ai &


