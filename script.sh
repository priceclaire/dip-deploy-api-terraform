#!/bin/bash
yum install nginx -y
echo "<html><body><h1>Hello from the other sideeeeeeee!</h1><h3>Yey! You are viewing this application on private instance ${instance_id}</h3></body></html>" > /usr/share/nginx/html/index.html
systemctl start nginx
