#!/bin/bash
echo "Starting Nginx..."
nginx

echo "Starting Flask Application..."
# The 'exec' command hands over control to Python. 
# This stays in the foreground inside the container to keep Docker alive!
exec ./venv/bin/python app.py