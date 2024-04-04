# compass_atividade_docker_aws 

**Objetivo:** Atividade consiste em criar a tipologia entregue, onde será criada duas instancias com um contêiner do wordpress escaláveis em zonas diferentes, onde o serviço do wordpress seja acessado através do loadbalance.

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
### Criando a VPC
-  No serviço de vpc, clique em ```Create VPC``` e selecione a opção ```VPC and more``` para exibir almas opções a mais.
- Selecione o nome da vpc  e o bloco ipv4 que será criado para ela.
- Selecione duas ```AZs``` (Zonas de disponibilidade).
- Selecione duas subnets publicas e privadas.
- Em ```ǸAT gateway``` selecione ```1 per AZ```.
- Em ```VPC endpoints``` marque a opção none.
### Criando os Security Groups
No serviço de EC2 em ```Security Groups```no painel lateral crie os seguintes grupos.

- **Sg-LoadBalance**
	- Type: HTTP
	- Protocol: TCP
	- Port range: 80
	- Source: 0.0.0.0/0 
- **Sg-Intancias**
	- Type: SSH
	- Protocol: TCP
	- Port range: 22
	- Source: Sg-LoadBalance
- **Sg-BancoRDS**
	- Type: MYSQL/AURORA
	- Protocol: TCP
	- Port range: 3306
	- Source: Sg-Instancias
- **Sg-EFS**
	- Type: NFS
	- Protocol: TCP
	- Port range: 2049
	- Source: Sg-Instancias
### Criando o Load Balancer
- No serviço de EC2, entre no serviço de 'Load Balancer' no painel lateral.
-  Clique em 'Create Load Balancer'.
-  Selecione o tipo 'Classic Load Balancer' e prossiga para a configuração básica do load balance:
	- Name: Nome do load balance.
	- Schema: Voltado para a internet (Internet-facing).
	- Network: Selecionar a VPC e as zonas de disponibilidade.
	- Security Group: Selecionar um grupo de segurança com tráfego HTTP liberado ```Sg-LoadBalance```.
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
	- Selecione a vpc em que o banco de dados será criado e o grupo de segurança ```Sg-BancoRDS```.
	- Em ```Avaliable Zone``` ```escolha no preference```.
	- Em ```Aditional configuration``` verifique se a porta de comunicação é a 3306.
- Clique em create data base.
### Criando o Elastic File System
- No serviço ```EFS da amazon```,  ```clique em create file system``` e em ```Customize```.
- Selecione o nome do sistema de arquivos e cloque em ```next```.
- Em network adicionaremos o grupo de segurança ```Sg-EFS```, com o trafego do protocolo NFS liberado para cada zona de disponibilidades.
- Clique em ```next``` até a etapa 4 para criar o efs.
### Criando o template
-  No serviço de ```ec2```, no painel lateral clique em ```Launch Templates``` e em ```Create launch template```.
- Selecione o nome do template.
- Na seção AMI selecione a opção de ```Quick Start```:
	- Imagem: ```Amazon Linux 2023 AMI.
	- Arquitetura: ```64-bit```.
	- Tipo de instancia: ```t3.small```.
- Selecione uma chave de acesso ssh (Key pair) ou crie uma.
- Selecione um grupo de segurança ```Sg-Instancias```.
- Em ```Advanced details``` prossiga até a opção de user data para adicionar o script com a instalação e configuração do docker, docker compose e o efs da instancia. Faça as alterações de conexão ao banco de dados.

```sh
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

cat > /home/ec2-user/docker-compose.yml << EOF
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
```
### Auto Scaling Group
- No serviço de EC2, no painel lateral clique na seção ```Auto Scaling Group``` e clique em ```create auto scaling group```.
- Selecione o nome do auto scaling e o template para a geração das instancias.
- Selecione  a VPC criada e as suas subnets privadas.
- Em Load balancing selecione ```Attach to an  existing load balance```.
- Em Attach to an existing load balance, selecione a ```Choose from Classic Load Balancers```e o load balance criado.
- Em heal checks marque a opção recomendada.
- Em ```Group size``` selecione a quantidade desejada de instancias e em ```Scaling``` selecione a quantidade minima e máxima de instancias.
### Criando um Endpoint
O endereço publico IPV4 não estará habilitado para a comunicação direta com a instancia, então será criado um endpoint para a comunicação interna da VPC.
- No serviço de VPC, na seção ```Endpoint```, clique em ```Create endpoint```.
- Selecione um nome ao endpoin (opcional).
- Selecione a categoria ```EC2 Instance Connect Endpoint```
- Selecione a VPC criada.
- Selecione o grupo de segurança ```Sg-LoadBalancer```
- Selecione qualquer uma das subnets privadas.

### Verificação
- Terminando a configuração do auto scaliing, as instancias já devem ser criadas automaticamente, onde pode ser consultada no próprio serviço de EC2 para ver as instancias em execução.
- No serviço do load balance ao clicar para ver os detelhes será possivel ver o endereço dns que será usado para acessa o serviço do wordpress pelo navegador.
	- Ex: ```lb-atividade-wordpress-21104951.us-east-1.elb.amazonaws.com```
- Na aba de ```Target Instances``` será possível ver se as instancias estão funcionando ou fora de serviço.
