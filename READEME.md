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
