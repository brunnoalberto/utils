#!/bin/bash

# ==============================================================================
# Script de Inicialização - Instalação de Ferramentas
# Ferramentas: Git, Docker, Java 21 (LTS), K6, JMeter
# ==============================================================================

# Cores para facilitar a leitura no terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Iniciando o script de instalação ===${NC}"

# 1. Instalar dependências básicas (Roda rápido se já estiverem instaladas)
echo -e "${YELLOW}[1/6] Verificando dependências básicas do sistema...${NC}"
sudo apt-get update -y > /dev/null || { echo -e "${RED}✘ Erro ao atualizar pacotes (apt-get update). Abortando.${NC}"; exit 1; }
sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release unzip > /dev/null || { echo -e "${RED}✘ Erro ao instalar dependências básicas. Abortando.${NC}"; exit 1; }

# 2. Instalar Git
echo -e "${YELLOW}[2/6] Verificando Git...${NC}"
if command -v git &> /dev/null; then
    echo -e "${GREEN}✔ Git já está instalado! Pulando...${NC}"
else
    sudo apt-get install -y git || { echo -e "${RED}✘ Erro ao instalar o Git. Abortando.${NC}"; exit 1; }
    command -v git &> /dev/null || { echo -e "${RED}✘ Falha crítica: Comando 'git' não encontrado após a instalação.${NC}"; exit 1; }
    echo -e "${GREEN}✔ Git instalado com sucesso!${NC}"
fi

# 3. Instalar Docker
echo -e "${YELLOW}[3/6] Verificando Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✔ Docker já está instalado! Pulando...${NC}"
else
    # Remover pacotes conflitantes antigos, se existirem (não falha o script se der erro aqui)
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null

    # Configurar chave e repositório oficial do Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes || { echo -e "${RED}✘ Erro ao adicionar chave GPG do Docker. Abortando.${NC}"; exit 1; }
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update -y > /dev/null
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo -e "${RED}✘ Erro ao instalar os pacotes do Docker. Abortando.${NC}"; exit 1; }

    # Habilitar o Docker para iniciar com o sistema e adicionar o usuário ao grupo
    sudo systemctl start docker || { echo -e "${RED}✘ Erro ao iniciar o serviço do Docker.${NC}"; exit 1; }
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    command -v docker &> /dev/null || { echo -e "${RED}✘ Falha crítica: Comando 'docker' não encontrado após a instalação.${NC}"; exit 1; }
    echo -e "${GREEN}✔ Docker instalado com sucesso! (Lembre-se de reiniciar a sessão depois para o grupo docker fazer efeito)${NC}"
fi

# 4. Instalar Java 21 (LTS) - OpenJDK
echo -e "${YELLOW}[4/6] Verificando Java 21 (LTS)...${NC}"
if dpkg -s openjdk-21-jdk &> /dev/null || command -v java &> /dev/null; then
    echo -e "${GREEN}✔ Java já está instalado! Pulando...${NC}"
else
    sudo apt-get install -y openjdk-21-jdk || { echo -e "${RED}✘ Erro ao instalar Java 21. Abortando.${NC}"; exit 1; }
    command -v java &> /dev/null || { echo -e "${RED}✘ Falha crítica: Comando 'java' não encontrado após a instalação.${NC}"; exit 1; }
    echo -e "${GREEN}✔ Java 21 instalado com sucesso!${NC}"
fi

# 5. Instalar Grafana K6
echo -e "${YELLOW}[5/6] Verificando K6...${NC}"
if command -v k6 &> /dev/null; then
    echo -e "${GREEN}✔ K6 já está instalado! Pulando...${NC}"
else
    curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/k6-archive-keyring.gpg || { echo -e "${RED}✘ Erro ao baixar chave GPG do K6. Abortando.${NC}"; exit 1; }
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list > /dev/null
    sudo apt-get update -y > /dev/null
    sudo apt-get install -y k6 || { echo -e "${RED}✘ Erro ao instalar o pacote k6. Abortando.${NC}"; exit 1; }
    
    command -v k6 &> /dev/null || { echo -e "${RED}✘ Falha crítica: Comando 'k6' não encontrado após a instalação.${NC}"; exit 1; }
    echo -e "${GREEN}✔ K6 instalado com sucesso!${NC}"
fi

# 6. Instalar Apache JMeter
echo -e "${YELLOW}[6/6] Verificando Apache JMeter...${NC}"
if command -v jmeter &> /dev/null || [ -d "/opt/jmeter" ]; then
    echo -e "${GREEN}✔ Apache JMeter já está instalado! Pulando...${NC}"
else
    JMETER_VERSION="5.6.3"
    JMETER_DIR="/opt/jmeter"

    wget https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz -O /tmp/jmeter.tgz || { echo -e "${RED}✘ Erro ao baixar o arquivo do JMeter. Verifique a conexão ou a versão.${NC}"; exit 1; }

    sudo mkdir -p ${JMETER_DIR}
    sudo tar -xf /tmp/jmeter.tgz -C ${JMETER_DIR} --strip-components=1 || { echo -e "${RED}✘ Erro ao extrair o JMeter.${NC}"; exit 1; }
    rm /tmp/jmeter.tgz
    
    # Criar link simbólico
    sudo ln -sf ${JMETER_DIR}/bin/jmeter /usr/local/bin/jmeter
    
    command -v jmeter &> /dev/null || { echo -e "${RED}✘ Falha crítica: Comando 'jmeter' não encontrado no PATH após a configuração.${NC}"; exit 1; }
    echo -e "${GREEN}✔ Apache JMeter instalado com sucesso em ${JMETER_DIR}!${NC}"
fi

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}        RESUMO DAS FERRAMENTAS E VERSÕES            ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Capturar versões
GIT_VER=$(git --version | awk '{print $3}')
DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
K6_VER=$(k6 version | awk '{print $2}')
# Pega apenas a versão do output do JMeter
JMETER_VER=$(jmeter -v 2>/dev/null | grep -Eo 'Version [0-9.]+' | awk '{print $2}') 

# Formatar a saída
printf "${GREEN}%-10s${NC} | %-20s\n" "Git" "$GIT_VER"
printf "${GREEN}%-10s${NC} | %-20s\n" "Docker" "$DOCKER_VER"
printf "${GREEN}%-10s${NC} | %-20s\n" "Java" "$JAVA_VER"
printf "${GREEN}%-10s${NC} | %-20s\n" "K6" "$K6_VER"
printf "${GREEN}%-10s${NC} | %-20s\n" "JMeter" "${JMETER_VER:-$JMETER_VERSION}"

echo -e "\n${BLUE}=== Instalação e verificação concluídas! ===${NC}"
