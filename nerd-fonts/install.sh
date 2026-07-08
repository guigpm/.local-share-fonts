#!/usr/bin/env bash
# Install Nerd Fonts
__ScriptVersion="1.0"

# Configurações de diretórios
FONT_DIR="$(pwd)"
DATA_DIR="${FONT_DIR}/../nerd-fonts-metadata"
REPO_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest"
mkdir -p "$DATA_DIR"

# Função de Ajuda (Help)
show_help() {
    echo -e "\033[1;34mGerenciador Inteligente de Nerd Fonts\033[0m"
    echo "Uso: $0 [comando] [argumentos]"
    echo ""
    echo -e "\033[1;33mComandos Disponíveis:\033[0m"
    echo "  install [Nome]  Baixa e instala/atualiza uma fonte específica."
    echo "  update          Verifica e instala atualizações para todas as fontes já baixadas."
    echo "  list            Lista todas as fontes gerenciadas por este script."
    echo "  help, -h, --help Exibe esta tela de ajuda."
    echo ""
    echo -e "\033[1;33mExemplos Práticos:\033[0m"
    echo "  $0 install FiraCode"
    echo "  $0 install JetBrainsMono"
    echo "  $0 install Hack"
    echo ""
    echo -e "\033[1;32mSugestões de Fontes Populares (Case Sensitive):\033[0m"
    echo "  - FiraCode        - JetBrainsMono    - Hack"
    echo "  - SourceCodePro   - Meslo            - UbuntuMono"
    echo "  - Inconsolata     - RobotoMono       - DejaVuSansMono"
    echo ""
    echo "Nota: As fontes são instaladas de forma isolada em: $FONT_DIR"
}

# Nova Função: Listar Fontes Instaladas
list_fonts() {
    echo -e "\033[1;34mFontes gerenciadas por este script:\033[0m"
    
    # Verifica se existem arquivos .version na pasta de metadados
    if [ -z "$(ls -A "$DATA_DIR"/*.version 2>/dev/null)" ]; then
        echo " Nenhuma fonte instalada até o momento."
        echo " Use o comando: $0 install [NomeDaFonte]"
    else
        # Loop para ler cada arquivo e mostrar o nome da fonte + versão atual
        for file in "$DATA_DIR"/*.version; do
            [ -e "$file" ] || continue
            local font_name=$(basename "$file" .version)
            local current_version=$(cat "$file")
            echo -e "  \033[1;32m-\033[0m $font_name (\033[0;36m$current_version\033[0m)"
        done
    fi
}

# Função para descobrir a versão estável atual sem usar a API restrita
get_latest_version_tag() {
    local location=$(curl -sI "$REPO_URL" | grep -i "location:" | tr -d '\r')
    local tag=$(echo "$location" | grep -oP 'releases/tag/\K.*')
    echo "$tag"
}

install_font() {
    local font_name=$1
    echo "Verificando fonte: $font_name..."

    local remote_version=$(get_latest_version_tag)
    
    if [ -z "$remote_version" ]; then
        echo "Erro: Não foi possível rastrear a última versão no GitHub. Verifique sua conexão."
        return 1
    fi

    local meta_file="$DATA_DIR/${font_name}.version"
    
    local download_url="${REPO_URL}/download/${font_name}.zip"

    if [ -f "$meta_file" ]; then
        local local_version=$(cat "$meta_file")
        if [ "$local_version" == "$remote_version" ]; then
            echo "✓ $font_name já está atualizada na última versão disponível ($local_version)."
            return 0
        fi
    fi

    echo "Baixando $font_name via redirecionamento automático (${remote_version})..."
    local zip_path="/tmp/${font_name}.zip"
    
    wget -q -L --show-progress -O "$zip_path" "$download_url"

    if [ $? -eq 0 ]; then
        echo "Extraindo arquivos em $FONT_DIR/$font_name..."
        mkdir -p "$FONT_DIR/$font_name"
        unzip -q -o "$zip_path" -d "$FONT_DIR/$font_name"
        rm "$zip_path"

        echo "$remote_version" > "$meta_file"
        echo "✓ $font_name instalada com sucesso!"
        return 0
    else
        echo "Erro: Falha ao baixar o arquivo. Verifique se o nome '$font_name' está correto."
        return 1
    fi
}

update_all() {
    echo "Iniciando checagem de atualizações..."
    local updated=0

    for file in "$DATA_DIR"/*.version; do
        [ -e "$file" ] || continue
        local font_name=$(basename "$file" .version)
        echo "----------------------------------------"
        install_font "$font_name"
        if [ $? -eq 0 ]; then updated=1; fi
    done

    if [ $updated -eq 1 ]; then
        echo "Atualizando o cache de fontes do Zorin OS..."
        fc-cache -f -v > /dev/null
        echo "Pronto! O Terminator já pode usar as fontes atualizadas."
    fi
}

# Tratamento dos argumentos informados
case "$1" in
    install)
        if [ -z "$2" ]; then
            echo "Erro: Você precisa especificar o nome da fonte."
            echo "Uso: $0 install [NomeDaFonte]"
            exit 1
        fi
        install_font "$2"
        fc-cache -f -v > /dev/null
        ;;
    update)
        update_all
        ;;
    list)
        list_fonts
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Comando inválido."
        echo ""
        show_help
        exit 1
        ;;
esac
