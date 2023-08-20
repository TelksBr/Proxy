#!/bin/bash

#!/bin/bash

# Função para instalar o proxy
install_proxy() {
    echo "Instalando o proxy..."
    {
        rm -f /usr/bin/proxy
        curl -s -L -o /usr/bin/proxy https://github.com/TelksBr/ProxyCracked/raw/main/proxy
        chmod +x /usr/bin/proxy
    } > /dev/null 2>&1
    echo "Proxy instalado com sucesso."
}

uninstall_proxy() {
    echo -e "\nDesinstalando o proxy..."
    
    # Encontra e remove todos os arquivos de serviço do proxy
    find /etc/systemd/system -name 'proxy_*.service' -exec sudo systemctl stop {} \;
    find /etc/systemd/system -name 'proxy_*.service' -exec sudo systemctl disable {} \;
    find /etc/systemd/system -name 'proxy_*.service' -exec sudo rm {} \;

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
    
    # Crie o arquivo de serviço
    SERVICE_FILE="/etc/systemd/system/proxy_service$PORT.service"
    echo "[Unit]" > $SERVICE_FILE
    echo "Description=Proxy Service on Port $PORT" >> $SERVICE_FILE
    echo "After=network.target" >> $SERVICE_FILE
    echo "" >> $SERVICE_FILE
    echo "[Service]" >> $SERVICE_FILE
    echo "ExecStart=/usr/bin/proxy --port $PORT \\" >> $SERVICE_FILE
    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        echo "--https --cert $CERT_PATH \\" >> $SERVICE_FILE
    else
        echo "--http \\" >> $SERVICE_FILE
    fi
    echo "--response \"$RESPONSE\" \\" >> $SERVICE_FILE
    if [[ $SSH_ONLY == "Y" || $SSH_ONLY == "y" ]]; then
        echo "--ssh-only \\" >> $SERVICE_FILE
    fi
    echo "Restart=always" >> $SERVICE_FILE
    echo "" >> $SERVICE_FILE
    echo "[Install]" >> $SERVICE_FILE
    echo "WantedBy=multi-user.target" >> $SERVICE_FILE
    
    
    # Recarregue o systemd
    sudo systemctl daemon-reload
    
    # Inicie o serviço e configure o início automático
    sudo systemctl start proxy_service$PORT
    sudo systemctl enable proxy_service$PORT
    
    echo "O serviço do proxy na porta $PORT foi configurado e iniciado automaticamente."
}

# Criar link simbólico para o script do menu
if [[ ! -f /usr/local/bin/mainproxy ]]; then
    ln -s "$(realpath $0)" /usr/local/bin/mainproxy
    echo "Link simbólico 'mainproxy' criado. Você pode executar o menu usando 'mainproxy'."
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
            echo "Serviços em execução:"
            systemctl list-units --type=service --state=running | grep proxy_
            read -p "Digite o número do serviço a ser parado: " service_number
            sudo systemctl stop proxy_$service_number
            echo "Serviço proxy_$service_number parado."
        ;;
        3)
            echo "Serviços em execução:"
            systemctl list-units --type=service --state=running | grep proxy_service
            read -p "Digite o número do serviço a ser reiniciado: " service_number
            sudo systemctl restart proxy_service$service_number
            echo "Serviço proxy_service$service_number reiniciado."
        ;;
        4)
            systemctl list-units --type=service --state=running | grep proxy_service
        ;;
        5)
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
