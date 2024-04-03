# compass_atividade_docker_aws 

**Objetivo:** 

---
#### Requisitos da Atividade

1. Instalação e configuração do DOCKER ou CONTAINERD no host EC2;
	--> Ponto adicional para o trabalho utilizar a instalação via script de Start Instance (user_data.sh)
2. Efetuar Deploy de uma aplicação Wordpress com:
	Container de aplicação
	RDS database Mysql
3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress.
4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress.

**Pontos de atenção:**
- Não utilizar ip público para saída do serviços WP (Evitem publicar o serviço WP via IP Público).
- Sugestão para o tráfego de internet sair pelo LB (Load Balancer Classic)
- Pastas públicas e estáticos do wordpress sugestão de utilizar o EFS (Elastic File Sistem).
- Fica a critério de cada integrante usar Dockerfile ou Dockercompose;
- Necessário demonstrar a aplicação wordpress funcionando (tela de login)
- Aplicação Wordpress precisa estar rodando na porta 80 ou 8080;
- Utilizar repositório git para versionamento;
- Criar documentação
---
### Criando o Load Balancer
- No serviço de EC2, entre no serviço de 'Load Balancer' no painel lateral.
-  Clique em 'Create Load Balancer'.
-  Selecione o tipo 'Classic Load Balancer' e prossiga para a configuração básica do load balance:
	- Name: Nome do load balance.
	- Schema: Voltado para a internet (Internet-facing).
	- Network: Selecionar a VPC e as zonas de disponibilidade.
	- Security Group: Selecionar um grupo de segurança com tráfego HTTP liberado.
	Ao concluir a configuração, será possível ver o DNS Name nos detalhes do load balance, usado para acessar as instâncias.
### Criando o Bando de Dados RDS
- No serviço ```Amazon RDS```, clique em ```create new database```.
- Selecione a opção ```Standard create``` para fazer as configurações manualmente.
- Selecione o  banco de dado ```Mysql``` .
- Selecione o template ```Free Tier```.
- Em ```Setting``` será definodo as configurações do banco de dados:
	- BD instance identifier: ```Nome do banco de dados```.
	- Master username: ```Nome de usuario```.
	- Master password: ```Senha do banco de dados```.
- Em ```Connectivity``` marque a opção ```Don´t connect to an EC2 compute resource```.
	- Selecione a vpc em que o banco de dados será criado.
	- Em ```Avaliable Zone``` ```escolha no preference```.
	- Em ```Aditional configuration``` verifique se a porta de comunicação é a 3306.
- Clique em create data base.
### Criando o Elastic File System
- No serviço ```EFS da amazon```,  ```clique em create file system``` e em ```Customize```.
- Selecione o nome do sistema de arquivos e cloque em ```next```.
- Em network adicionaremos o grupo de segurança, com o trafego do protocolo nfs liberado para cada zona de disponibilidades.
- Clique em ```next``` até a etapa 4 para criar o efs.
### Criando o template
-  No serviço de ```ec2```, no painel lateral clique em ```Launch Templates``` e em ```Create launch template```.
- Selecione o nome do template.
- Na seção AMI selecione a opção de ```Quick Start```:
	- Imagem: ```Amazon Linux 2023 AMI.
	- Arquitetura: ```64-bit```.
	- Tipo de instancia: ```t3.small```.
- Selecione uma chave de acesso ssh (Key pair) ou crie uma.
- Selecione um grupo de segurança com acesso a ssh e http.
- Em ```Advanced details``` prossiga até a opção de user data para adicionar o script com a instalação e configuração do docker, docker compose e o efs da instancia. Faça as alterações de conexão ao banco de dados.

	```bash
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
      WORDPRESS_DB_HOST: <ENDERECO DO BANCO DE DADOS>
      WORDPRESS_DB_USER: <USUARIO>
      WORDPRESS_DB_PASSWORD: <SENHA>
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_TABLE_PREFIX: wp_
EOF

sudo docker-compose -f ~/docker-compose.yml up -d
	```

### Auto Scaling Group
