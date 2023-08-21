#!/bin/bash

# Função para instalar o proxy
install_proxy() {
    echo "Instalando o proxy..."
    {
        rm -f /usr/bin/proxy
        curl -s -L -o /usr/bin/proxy https://raw.githubusercontent.com/TelksBr/proxy/main/proxy
        chmod +x /usr/bin/proxy
    } > /dev/null 2>&1
    echo "Proxy instalado com sucesso."
}

uninstall_proxy() {
    echo -e "\nDesinstalando o proxy..."

    # Encontra e remove todos os arquivos de serviço do proxy
    service_files=$(find /etc/systemd/system -name 'proxy-*.service')
    for service_file in $service_files; do
        service_name=$(basename "$service_file")
        service_name=${service_name%.service}
        
        # Verifica se o serviço está ativo antes de tentar parar e desabilitar
        if sudo systemctl is-active "$service_name" &> /dev/null; then
            sudo systemctl stop "$service_name"
            sudo systemctl disable "$service_name"
        fi
        
        sudo rm -f "$service_file"
        echo "Serviço $service_name parado e arquivo de serviço removido: $service_file"
    done

    # Remove o arquivo binário do proxy
    sudo rm -f /usr/bin/proxy
    
    echo "Proxy desinstalado com sucesso."
}

# Configurar e iniciar o serviço
configure_and_start_service() {
    read -p "Digite a porta a ser usada (--port): " PORT
    read -p "Você quer usar HTTP (H) ou HTTPS (S)? [H/S]: " HTTP_OR_HTTPS
    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        read -p "Digite o caminho do certificado (--cert): " CERT_PATH
    fi
    read -p "Digite o conteúdo da resposta HTTP (--response): " RESPONSE
    read -p "Você quer usar apenas SSH (Y/N)? [Y/N]: " SSH_ONLY
    
    # Defina as opções de comando
    OPTIONS="--port $PORT"
    
    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        OPTIONS="$OPTIONS --https --cert $CERT_PATH"
    else
        OPTIONS="$OPTIONS --http"
    fi
    
    if [[ $SSH_ONLY == "Y" || $SSH_ONLY == "y" ]]; then
        OPTIONS="$OPTIONS --ssh-only"
    fi
    
    # Crie o arquivo de serviço
    SERVICE_FILE="/etc/systemd/system/proxy-$PORT.service"
    echo "[Unit]" > $SERVICE_FILE
    echo "Description=Proxy Service on Port $PORT" >> $SERVICE_FILE
    echo "After=network.target" >> $SERVICE_FILE
    echo "" >> $SERVICE_FILE
    echo "[Service]" >> $SERVICE_FILE
    echo "ExecStart=/usr/bin/proxy $OPTIONS --response \"$RESPONSE\"" >> $SERVICE_FILE
    echo "Restart=always" >> $SERVICE_FILE
    echo "" >> $SERVICE_FILE
    echo "[Install]" >> $SERVICE_FILE
    echo "WantedBy=multi-user.target" >> $SERVICE_FILE
    
    # Recarregue o systemd
    sudo systemctl daemon-reload
    
    # Inicie o serviço e configure o início automático
    sudo systemctl start proxy-$PORT
    sudo systemctl enable proxy-$PORT
    
    echo "O serviço do proxy na porta $PORT foi configurado e iniciado automaticamente."
}

stop_and_remove_service() {
    read -p "Digite o número do serviço a ser parado e removido: " service_number
    
    # Parar o serviço
    sudo systemctl stop proxy-$service_number
    
    # Desabilitar o serviço
    sudo systemctl disable proxy-$service_number
    
    # Encontrar e remover o arquivo do serviço
    service_file=$(find /etc/systemd/system -name "proxy-$service_number.service")
    if [ -f "$service_file" ]; then
        sudo rm "$service_file"
        echo "Arquivo de serviço removido: $service_file"
    else
        echo "Arquivo de serviço não encontrado para o serviço proxy-$service_number."
    fi
    
    echo "Serviço proxy-$service_number parado e removido."
}

#!/bin/bash

# Função para baixar o install.sh e criar o link simbólico
download_and_configure_install_script() {
    # Baixar o install.sh
    curl -s -L -o /usr/local/bin/installproxy https://raw.githubusercontent.com/TelksBr/proxy/main/install.sh
    chmod +x /usr/local/bin/installproxy

    # Criar o link simbólico
    ln -s /usr/local/bin/installproxy /usr/local/bin/mainproxy
    echo "Script installproxy baixado e configurado. Você pode executar o menu usando 'mainproxy'."
}

# Verificar se o script installproxy já existe
if [[ ! -f /usr/local/bin/installproxy ]]; then
    download_and_configure_install_script
fi

# ... (restante do seu script)

# Menu de gerenciamento
while true; do
    clear
    echo "Menu de Gerenciamento do Serviço Proxy:"
    # ... (restante do seu menu)
done

fi

# Menu de gerenciamento
while true; do
    clear
    echo "Menu de Gerenciamento do Serviço Proxy:"
    echo "1. Configurar e Iniciar um Novo Serviço"
    echo "2. Parar um Serviço"
    echo "3. Reiniciar um Serviço"
    echo "4. Ver Status dos Serviços"
    echo "5. Reinstalar o Proxy"
    echo "6. Desinstalar o Proxy"
    echo "7. Sair"
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            configure_and_start_service
        ;;
        2)
            stop_and_remove_service
        ;;
        3)
            echo "Serviços em execução:"
            systemctl list-units --type=service --state=running | grep proxy-
            read -p "Digite o número do serviço a ser reiniciado: " service_number
            sudo systemctl restart proxy-$service_number
            echo "Serviço proxy-$service_number reiniciado."
        ;;
        4)
            systemctl list-units --type=service --state=running | grep proxy-
        ;;
        5)
            echo "Desinstalando o proxy antes de reinstalar..."
            uninstall_proxy
            install_proxy
        ;;
        6)
            uninstall_proxy
        ;;
        7)
            echo "Saindo."
            break
        ;;
        *)
            echo "Opção inválida. Escolha uma opção válida."
        ;;
    esac
    
    read -p "Pressione Enter para continuar..."
done
