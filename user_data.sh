#!/bin/bash

sudo yum update -y

sudo yum install docker -y 
sudo yum install amazon-efs-utils -y

sudo usermod -aG docker $(whoami)

sudo systemctl start docker
sudo systemctl enable docker

sudo mkdir /mnt/efs
