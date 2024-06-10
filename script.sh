#!/bin/bash
yum install nginx -y
echo "Hello World from $(hostname -f)" > /usr/share/nginx/html/index.html
systemctl start nginx
