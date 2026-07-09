#!/usr/bin/env bash
# Install Nerd Fonts con Busca Remota por Proximidade e Cache JSON Local
__ScriptVersion="1.3"

# Configurações de diretórios
FONT_DIR="$(pwd)"
DATA_DIR="${FONT_DIR}/../nerd-fonts-metadata"
REPO_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest"
mkdir -p "$DATA_DIR"

JSON_FILE="$DATA_DIR/latest_release.json"
API_URL="${REPO_URL/github.com/api.github.com\/repos}"
#echo "$API_URL" # esperado https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest

# Função de Ajuda (Help)
show_help() {
    echo -e "\033[1;34mGerenciador Inteligente de Nerd Fonts\033[0m"
    echo "Uso: $0 [comando] [argumentos]"
    echo ""
    echo -e "\033[1;33mComandos Disponíveis:\033[0m"
    echo "  install [Nome]    Baixa e instala uma fonte específica."
    echo "  uninstall [Nome]  Remove completamente a fonte e seus metadados."
    echo "  update            Verifica e instala atualizações para todas as fontes já baixadas."
    echo "  list              Lista todas as fontes gerenciadas por este script."
    echo "  list-remote       Busca na API do GitHub e lista TODAS as fontes existentes para download."
    echo "  update-cache      Busca na API do GitHub e força a atualização local do arquivo de cache."
    echo "  help, -h, --help   Exibe esta tela de ajuda."
    echo ""
    echo -e "\033[1;33mExemplos Práticos:\033[0m"
    echo "  $0 install FiraCode"
    echo "  $0 install JetBrainsMono"
    echo ""
    echo "Nota: O instalador possui algoritmo de correção ortográfica por proximidade."
}

# Listar Fontes Instaladas Localmente
list_fonts() {
    echo -e "\033[1;34mFontes gerenciadas por este script localmente:\033[0m"
    if [ -z "$(ls -A "$DATA_DIR"/*.version 2>/dev/null)" ]; then
        echo " Nenhuma fonte instalada até o momento."
    else
        for file in "$DATA_DIR"/*.version; do
            [ -e "$file" ] || continue
            local font_name=$(basename "$file" .version)
            local current_version=$(cat "$file")
            echo -e "  \033[1;32m-\033[0m $font_name (\033[0;36m$current_version\033[0m)"
        done
    fi
}

# Descobre a versão estável atual remotamente de forma leve (cabeçalho HTTP)
get_latest_version_tag() {
    local location=$(curl -sI "$REPO_URL" | grep -i "location:" | tr -d '\r')
    local tag=$(echo "$location" | grep -oP 'releases/tag/\K.*')
    echo "$tag"
}

api_download_json_file() {
    curl -s --request GET --url "$API_URL" --header "Accept: application/vnd.github+json" > "$JSON_FILE"
}

# Gerencia o cache do JSON local de forma inteligente para economizar requisições
cache_api_json() {
    
    # 1. Se o arquivo local não existir, faz o download inicial obrigatório
    if [ ! -f "$JSON_FILE" ]; then
        echo "Baixando catálogo de fontes do GitHub pela primeira vez..."
        api_download_json_file
        return 0
    fi

    # 2. Se o arquivo já existe, lê a versão salva localmente nele
    local local_version=$(grep -oP '"tag_name": "\K[^"]*' "$JSON_FILE")

    # 3. Faz uma checagem leve para ver a versão atual do servidor
    local remote_version=$(get_latest_version_tag)

    # 4. Se a versão mudou, atualiza o JSON local com os novos dados
    if [ "$local_version" != "$remote_version" ]; then
        echo "Nova versão detectada ($remote_version). Atualizando catálogo local..."
        api_download_json_file
    fi
}

# Listar Fontes Remotas lendo o arquivo JSON local
list_remote_fonts() {
    cache_api_json # Garante que o arquivo existe e está atualizado
    
    local assets=$(grep -oP '"name": "\K[^"]*' "$JSON_FILE" | grep '\.zip' | sed 's/\.zip//' | sort)
    
    if [ -z "$assets" ]; then
        echo "Erro ao processar a lista remota localmente."
        return 1
    fi

    echo -e "\033[1;34mFontes disponíveis para instalação no repositório oficial:\033[0m"
    echo "$assets" | column -c 80 | sed 's/^/  /'
}

# Sugestão por Proximidade de Digitação lendo o arquivo JSON local
suggest_closest_fonts() {
    local typed_name=$1
    echo -e "\033[1;31mErro: A fonte '$typed_name' não foi mapeada com esse nome exato.\033[0m"
    echo "Buscando sugestões no catálogo local..."

    local remote_list=$(grep -oP '"name": "\K[^"]*' "$JSON_FILE" | grep '\.zip' | sed 's/\.zip//' | sort)

    echo ""
    echo -e "\033[1;33mVocê quis dizer uma destas fontes?:\033[0m"
    
    # Executa uma filtragem inteligente (Ignora case-sensitive e busca correspondências parciais)
    # Lista as 3 melhores aproximações baseadas no texto digitado
    local suggestions=$(echo "$remote_list" | grep -i "$typed_name" | head -n 3)
    
    # Se a busca direta parcial falhar, tenta quebrar em pedaços pequenos de letras
    if [ -z "$suggestions" ]; then
        local first_letters=${typed_name:0:3}
        suggestions=$(echo "$remote_list" | grep -i "$first_letters" | head -n 3)
    fi

    if [ -n "$suggestions" ]; then
        echo "$suggestions" | sed 's/^/  👉  install /'
    else
        echo " Nenhuma fonte parecida foi encontrada. Rode: $0 list-remote"
    fi
}

# Remove fisicamente a fonte e os registros locais de metadados
uninstall_font() {
    local font_name=$1
    local meta_file="$DATA_DIR/${font_name}.version"
    local target_font_dir="$FONT_DIR/$font_name"
    local found=0

    echo "Iniciando remoção de: $font_name..."

    if [ -d "$target_font_dir" ]; then
        rm -rf "$target_font_dir"
        found=1
    fi

    if [ -f "$meta_file" ]; then
        rm -f "$meta_file"
        found=1
    fi

    if [ $found -eq 1 ]; then
        echo -e "\033[1;32m✓ Fonte $font_name removida com sucesso!\033[0m"
        return 0
    else
        echo -e "\033[1;31mErro: A fonte '$font_name' não foi instalada por este script.\033[0m"
        return 1
    fi
}

# Instala a fonte desejada extraindo os dados diretamente do cache local do JSON
install_font() {
    local font_name=$1
    echo "Verificando fonte: $font_name..."

    cache_api_json # Valida/Garante o JSON local atualizado antes de proceder

    # Extrai dados do arquivo local de metadados (Sem chamadas redundantes de rede)
    local remote_version=$(grep -oP '"tag_name": "\K[^"]*' "$JSON_FILE")
    local download_url=$(grep -oP '"browser_download_url": "\K[^"]*' "$JSON_FILE" | grep -i "${font_name}.zip" | head -n 1)

    if [ -z "$download_url" ]; then
        suggest_closest_fonts "$font_name"
        return 1
    fi

    local meta_file="$DATA_DIR/${font_name}.version"

    if [ -f "$meta_file" ]; then
        local local_version=$(cat "$meta_file")
        if [ "$local_version" == "$remote_version" ]; then
            echo "✓ $font_name já está atualizada na última versão disponível ($local_version)."
            return 0
        fi
    fi

    echo "Baixando $font_name via redirecionamento automático..."
    local zip_path="/tmp/${font_name}.zip"
    
    wget -q -L --show-progress -O "$zip_path" "$download_url"

    if [ $? -eq 0 ] && [ -s "$zip_path" ]; then
        echo "Extraindo arquivos em $FONT_DIR/$font_name..."
        mkdir -p "$FONT_DIR/$font_name"
        unzip -q -o "$zip_path" -d "$FONT_DIR/$font_name"
        rm "$zip_path"

        echo "$remote_version" > "$meta_file"
        echo -e "\033[1;32m✓ $font_name instalada com sucesso!\033[0m"
        return 0
    else
        rm -f "$zip_path"
        echo "Erro ao baixar os arquivos da fonte."
        return 1
    fi
}

# Varre as fontes locais existentes e atualiza se o JSON remoto indicar novas versões
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
        echo "Atualizando o cache de fontes..."
        fc-cache -f -v > /dev/null
    fi
}

# Tratamento dos argumentos informados
case "$1" in
    install)
        if [ -z "$2" ]; then
            echo "Erro: Você precisa especificar o nome da fonte."
            exit 1
        fi
        install_font "$2"
        fc-cache -f -v > /dev/null 2>&1
        ;;
    uninstall)
        if [ -z "$2" ]; then
            echo "Erro: Você precisa especificar o nome da fonte."
            exit 1
        fi
        uninstall_font "$2"
        fc-cache -f -v > /dev/null 2>&1
        ;;
    update)
        update_all
        ;;
    list)
        list_fonts
        ;;
    list-remote)
        list_remote_fonts
        ;;
    update-cache)
        api_download_json_file
        echo "Updated."
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
