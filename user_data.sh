#!/bin/bash
sudo yum update -y

sudo yum install amazon-efs-utils -y
sudo yum install docker -y 

sudo systemctl enable docker.socket
sudo systemctl start docker.socket

sudo usermod -aG docker ec2-user

sudo curl -L https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo chmod 666 /var/run/docker.sock

mkdir /mnt/efs

sudo echo "fs-000ad3517f2d7c878.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

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
      WORDPRESS_DB_HOST: <ENDPOINT DO BANDO DE DADOS>
      WORDPRESS_DB_USER: <USUARIO DO BANCO DE DADOS>
      WORDPRESS_DB_PASSWORD: <SENHA DO BANCO DE DADOS>
      WORDPRESS_DB_NAME: <NOME DO BANCO Initial data base>
      WORDPRESS_TABLE_PREFIX: wp_
EOF

sudo docker-compose -f /home/ec2-user/docker-compose.yml up -d