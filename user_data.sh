#!/bin/bash

sudo yum update -y

sudo yum install amazon-efs-utils -y
sudo yum install docker -y 

sudo systemctl start docker.socket
sudo systemctl enable docker.socket

sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker $(whoami)

sudo curl -L https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

mkdir /mnt/efs

sudo systemctl restart --now docker

