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

sudo systemctl restart --now docker

mkdir /mnt/efs

sudo echo "fs-0c31b9d5b408cdb88.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

sudo mount -a

cat > /home/ec2-user/docker-compose.yml <<EOF
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: wordpress.cju0uqguetsz.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: wordpressadmin
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_TABLE_PREFIX: wp_
EOF

sudo yum update
sudo docker-compose -f ~/docker-compose.yml up -d