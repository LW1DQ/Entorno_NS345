#!/bin/bash
# =============================================================================
# Script de Instalación de Herramientas para Investigación en Redes
# Entorno de Simulación Avanzado - NS-3.48 y Herramientas de Análisis
# Versión mejorada que integra lo mejor de múltiples scripts
# =============================================================================

set -o pipefail
trap 'log_error "Script interrumpido. Saliendo..."; exit 1' INT TERM

# =============================================================================
# Configuración general
# =============================================================================
NS3_VERSION="3.48"
NS3_DIR="$HOME/ns-$NS3_VERSION"
NS3_TARBALL="ns-$NS3_VERSION.tar.bz2"
NS3_URL="https://www.nsnam.org/releases/$NS3_TARBALL"
NS3_MODULES="core,network,internet,mobility,wifi,mesh,energy,flow-monitor,aodv,dsdv,olsr,applications,csma,point-to-point,wave,bridge,traffic-control,netanim"

# Opción para instalar 5G-LENA (cambiar a true para activar)
INSTALL_5GLENA=false

# =============================================================================
# Colores y funciones de logging
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_message() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }

# =============================================================================
# Funciones de utilidad
# =============================================================================
show_banner() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  INSTALACIÓN DE HERRAMIENTAS PARA INVESTIGACIÓN EN REDES"
    echo "  NS-3 $NS3_VERSION, Herramientas de Análisis y Entorno de Desarrollo"
    echo "  (Script mejorado - $(date +'%Y-%m-%d'))"
    echo "============================================================================="
    echo -e "${NC}"
}

check_ubuntu() {
    if [[ ! -f /etc/os-release ]] || ! grep -qi "Ubuntu" /etc/os-release; then
        log_error "Este script está diseñado para Ubuntu Desktop."
        exit 1
    fi
    source /etc/os-release
    log_info "Sistema detectado: ${PRETTY_NAME:-Ubuntu}"
    # Se intenta continuar en cualquier versión, pero se advierte si no es 26.x
    if [[ "${VERSION_ID:-}" != 26* ]]; then
        log_warning "El script fue adaptado para Ubuntu 26.x. Se continuará en ${VERSION_ID:-versión desconocida}."
    fi
}

check_disk_space() {
    log_info "Verificando espacio en disco..."
    local required_space=8000000  # 8GB en KB
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $required_space ]]; then
        log_error "Espacio insuficiente. Se requieren al menos 8GB libres."
        return 1
    fi
    log_message "✓ Espacio en disco suficiente"
    return 0
}

backup_existing_config() {
    log_info "Creando backup de configuraciones existentes..."
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    [[ -f ~/.bashrc ]] && cp ~/.bashrc "$backup_dir/bashrc" && log_message "✓ Backup de .bashrc creado"
    [[ -f ~/.gitconfig ]] && cp ~/.gitconfig "$backup_dir/gitconfig" && log_message "✓ Backup de .gitconfig creado"

    echo "$backup_dir" > ~/.last_config_backup
    log_message "✓ Backups guardados en: $backup_dir"
}

update_system() {
    log_info "Actualizando sistema..."
    sudo apt update && sudo apt upgrade -y
    log_message "✓ Sistema actualizado"
}

# Instalación inteligente de paquetes: verifica si ya está instalado
install_apt_package() {
    local package="$1"
    local required="${2:-true}"  # Por defecto es requerido
    if dpkg -s "$package" >/dev/null 2>&1; then
        log_message "✓ $package ya instalado"
        return 0
    fi
    log_info "Instalando $package..."
    if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$package"; then
        log_message "✓ $package instalado"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            log_error "Error instalando paquete requerido: $package"
            return 1
        else
            log_warning "No se pudo instalar paquete opcional: $package. Continuando..."
            return 0
        fi
    fi
}

install_system_dependencies() {
    log_info "Instalando dependencias del sistema..."

    # Paquetes requeridos (si fallan, el script se detiene)
    local required_packages=(
        "build-essential" "gcc" "g++" "cmake" "ninja-build" "pkg-config"
        "python3" "python3-pip" "python3-dev" "python3-venv" "python3-setuptools"
        "git" "wget" "curl" "unzip" "tar" "bzip2" "xz-utils" "ca-certificates"
        "sqlite3" "libsqlite3-dev" "libboost-all-dev" "libssl-dev" "libxml2-dev"
        "libgtk-3-dev" "libgsl-dev" "libeigen3-dev" "openmpi-bin" "openmpi-common" "libopenmpi-dev"
        "doxygen" "graphviz" "imagemagick" "texlive" "texlive-latex-extra" "texlive-font-utils"
        "wireshark" "tshark" "tcpdump" "nmap" "iperf3" "traceroute" "mtr" "net-tools"
        "vim" "nano" "htop" "tree" "jq" "screen" "tmux"
    )

    # Paquetes opcionales (si fallan, solo se advierte)
    local optional_packages=(
        "libgstreamer1.0-dev" "libgstreamer-plugins-base1.0-dev" "libgstreamer-plugins-bad1.0-dev"
        "gstreamer1.0-plugins-base" "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-bad"
        "gstreamer1.0-plugins-ugly" "gstreamer1.0-libav" "gstreamer1.0-tools" "gstreamer1.0-x"
        "gstreamer1.0-alsa" "gstreamer1.0-gl" "gstreamer1.0-gtk3" "gstreamer1.0-pulseaudio"
    )

    for package in "${required_packages[@]}"; do
        if ! install_apt_package "$package" true; then
            return 1
        fi
    done

    for package in "${optional_packages[@]}"; do
        install_apt_package "$package" false
    done

    # Configurar Wireshark para usuarios no-root
    if getent group wireshark >/dev/null 2>&1; then
        sudo usermod -a -G wireshark "$USER"
        log_message "✓ Usuario agregado al grupo wireshark"
    else
        log_warning "No se encontró el grupo wireshark; puede requerir configuración manual."
    fi

    log_message "✓ Dependencias del sistema instaladas"
    return 0
}

setup_git_config() {
    log_info "Configurando Git para control de versiones..."

    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        log_message "✓ Git ya está configurado"
        log_info "Usuario: $(git config --global user.name)"
        log_info "Email: $(git config --global user.email)"
        return 0
    fi

    echo -e "${YELLOW}Configuración de Git:${NC}"
    read -r -p "Ingrese su nombre completo: " git_name
    read -r -p "Ingrese su email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor nano
    git config --global pull.rebase false
    git config --global core.autocrlf input

    log_message "✓ Git configurado correctamente"
}

create_basic_structure() {
    log_info "Creando estructura básica de trabajo..."

    mkdir -p workspace docs backup results traces scripts notebooks

    cat > .gitignore << 'EOF'
# Resultados, trazas y logs
*.pcap
*.tr
*.log
*.dat
*.csv
*.tmp
results/
traces/
logs/

# Python
__pycache__/
*.py[cod]
.venv/
venv/
.ipynb_checkpoints/

# NS-3 / compilación
*.o
*.a
*.so
build/
cmake-cache/
.cache/
compile_commands.json
.lock-waf*
.lock-ns3*

# Temporales
*~
.DS_Store
Thumbs.db
EOF

    log_message "✓ Estructura básica creada"
}

# =============================================================================
# Instalación de NS-3
# =============================================================================
add_ns3_to_path() {
    local path_line="export PATH=\$PATH:\$HOME/ns-$NS3_VERSION"
    if ! grep -Fq "ns-$NS3_VERSION" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# NS-3 $NS3_VERSION" >> "$HOME/.bashrc"
        echo "$path_line" >> "$HOME/.bashrc"
    fi
    export PATH="$PATH:$NS3_DIR"
}

install_ns3() {
    log_info "Instalando NS-3 $NS3_VERSION..."

    if [[ -d "$NS3_DIR" ]]; then
        log_warning "Ya existe el directorio: $NS3_DIR"
        read -r -p "¿Desea reinstalar NS-3 $NS3_VERSION? (y/N): " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            rm -rf "$NS3_DIR"
        else
            log_info "Usando instalación existente"
            add_ns3_to_path
            return 0
        fi
    fi

    cd "$HOME" || return 1
    rm -f "$NS3_TARBALL"

    log_info "Descargando NS-3 $NS3_VERSION desde $NS3_URL..."
    if ! wget -O "$NS3_TARBALL" "$NS3_URL"; then
        log_error "Error descargando NS-3 $NS3_VERSION"
        return 1
    fi

    log_info "Extrayendo NS-3 $NS3_VERSION..."
    tar xjf "$NS3_TARBALL"
    cd "$NS3_DIR" || return 1

    log_info "Configurando NS-3 $NS3_VERSION..."
    if ! ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules="$NS3_MODULES"; then
        log_warning "La configuración con lista explícita de módulos falló. Reintentando con módulos por defecto."
        if ! ./ns3 configure --enable-examples --enable-tests --build-profile=optimized; then
            log_error "Error configurando NS-3 $NS3_VERSION"
            return 1
        fi
    fi

    local cores
    cores=$(nproc)
    log_info "Compilando NS-3 $NS3_VERSION con $cores cores..."
    if ! ./ns3 build -j"$cores"; then
        log_error "Error compilando NS-3 $NS3_VERSION"
        return 1
    fi

    add_ns3_to_path
    log_message "✓ NS-3 $NS3_VERSION instalado correctamente en $NS3_DIR"

    # Limpiar el comprimido descargado
    rm -f "$HOME/$NS3_TARBALL"
    return 0
}

# =============================================================================
# Instalación de 5G-LENA (opcional)
# =============================================================================
install_5g_lena() {
    if [[ "$INSTALL_5GLENA" != "true" ]]; then
        log_info "5G-LENA no está habilitado. Saltando instalación."
        return 0
    fi

    log_info "Instalando módulo 5G-LENA..."

    if [[ ! -d "$NS3_DIR" ]]; then
        log_error "NS-3 no instalado en $NS3_DIR. No se puede instalar 5G-LENA."
        return 1
    fi

    cd "$NS3_DIR" || return 1

    if [[ -d "contrib/nr" ]]; then
        log_warning "El módulo 5G-LENA ya existe en contrib/nr"
        read -r -p "¿Desea reinstalarlo? (y/N): " reply
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            log_info "Usando módulo existente"
            return 0
        fi
        rm -rf contrib/nr
    fi

    log_info "Clonando repositorio 5G-LENA desde GitLab..."
    if ! git clone https://gitlab.com/cttc-lena/nr.git contrib/nr; then
        log_error "Error clonando repositorio 5G-LENA"
        return 1
    fi

    cd contrib/nr || return 1
    log_info "Seleccionando rama compatible con NS-3 $NS3_VERSION..."
    if ! git checkout -b 5g-lena-v4.1.y origin/5g-lena-v4.1.y; then
        log_warning "No se pudo cambiar a la rama 5g-lena-v4.1.y. Se usará la rama por defecto."
    fi
    cd "$NS3_DIR" || return 1

    # Reconfigurar NS-3 incluyendo el módulo nr
    log_info "Reconfigurando NS-3 con módulo 5G-LENA..."
    ./ns3 clean
    if ! ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules="$NS3_MODULES,nr"; then
        log_error "Error reconfigurando NS-3 con 5G-LENA"
        return 1
    fi

    log_info "Recompilando NS-3 con 5G-LENA..."
    local cores
    cores=$(nproc)
    if ! ./ns3 build -j"$cores"; then
        log_error "Error compilando NS-3 con 5G-LENA"
        return 1
    fi

    log_message "✓ 5G-LENA instalado y compilado correctamente"
    return 0
}

# =============================================================================
# Instalación de dependencias Python
# =============================================================================
install_python_dependencies() {
    log_info "Instalando dependencias Python en entorno virtual..."

    if [[ ! -d "venv" ]] || [[ ! -f "venv/bin/activate" ]]; then
        rm -rf venv
        if ! python3 -m venv venv; then
            log_error "Error creando entorno virtual"
            return 1
        fi
    fi

    # shellcheck disable=SC1091
    source venv/bin/activate
    if ! python -m pip install --upgrade pip wheel setuptools --quiet; then
        log_error "Error actualizando pip"
        deactivate
        return 1
    fi

    local packages=(
        "pandas" "numpy" "matplotlib" "seaborn" "psutil" "scipy" "scikit-learn"
        "jupyter" "notebook" "plotly" "networkx" "pyshark" "scapy"
    )

    for package in "${packages[@]}"; do
        log_info "Instalando $package..."
        if ! pip install "$package" --quiet; then
            deactivate
            log_error "Error instalando $package"
            return 1
        fi
    done

    deactivate
    log_message "✓ Dependencias Python instaladas"
    return 0
}

# =============================================================================
# Configuración de permisos y límites del sistema
# =============================================================================
setup_permissions() {
    log_info "Configurando permisos..."
    chmod +x ./*.sh 2>/dev/null || true
    chmod +x ./*.py 2>/dev/null || true

    if ! grep -q "nofile 65536" /etc/security/limits.conf 2>/dev/null; then
        echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null
        echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null
    fi

    log_message "✓ Permisos y límites configurados"
}

# =============================================================================
# Documentación
# =============================================================================
create_initial_docs() {
    log_info "Creando documentación inicial..."

    cat > README.md << EOF
# Entorno de Investigación en Redes - NS-3 $NS3_VERSION

## Descripción
Entorno para investigación en redes sobre Ubuntu Desktop con NS-3 $NS3_VERSION, herramientas de análisis y entorno Python.

## Herramientas Instaladas

### Simulación
- **NS-3 $NS3_VERSION**
- Módulos habilitados: $NS3_MODULES
$(if [[ "$INSTALL_5GLENA" == "true" ]]; then echo "- **5G-LENA** (módulo nr) instalado."; else echo "- **5G-LENA**: no instalado (opcional)."; fi)

### Análisis de Red
- Wireshark/tshark
- tcpdump
- nmap
- iperf3
- traceroute, mtr, net-tools

### Desarrollo
- Python 3 con entorno virtual
- Git
- pandas, numpy, matplotlib, seaborn, scipy, scikit-learn, jupyter, plotly, networkx, pyshark y scapy

## Estructura
\`\`\`
├── workspace/    # Proyectos y simulaciones
├── scripts/      # Scripts auxiliares
├── notebooks/    # Notebooks de análisis
├── results/      # Resultados generados
├── traces/       # Trazas .pcap/.tr
├── docs/         # Documentación
├── backup/       # Respaldos
└── venv/         # Entorno virtual Python
\`\`\`

## Uso Básico

### Activar entorno Python
\`\`\`bash
source venv/bin/activate
\`\`\`

### Verificar NS-3
\`\`\`bash
source ~/.bashrc
ns3 --version
ns3 show version
ns3 show config
ns3 run first
\`\`\`
$(if [[ "$INSTALL_5GLENA" == "true" ]]; then echo "
### Probar 5G-LENA
\`\`\`bash
ns3 run cttc-nr-demo
\`\`\`
"; fi)

### Compilar nuevamente
\`\`\`bash
cd ~/ns-$NS3_VERSION
./ns3 configure --enable-examples --enable-tests --build-profile=optimized
./ns3 build -j\$(nproc)
\`\`\`

## Nota
Para usar Wireshark sin sudo puede ser necesario cerrar sesión y volver a ingresar.
EOF

    mkdir -p docs
    cat > docs/TOOLS_GUIDE.md << EOF
# Guía de Herramientas Instaladas

## NS-3 $NS3_VERSION

- Ubicación: \`~/ns-$NS3_VERSION/\`
- Comando principal: \`ns3\`

Comandos útiles:
\`\`\`bash
cd ~/ns-$NS3_VERSION
./ns3 --version
./ns3 show version
./ns3 show examples
./ns3 show targets
./ns3 run first
./ns3 build
./ns3 clean
\`\`\`
$(if [[ "$INSTALL_5GLENA" == "true" ]]; then echo "
### 5G-LENA
- Ejemplo: \`./ns3 run cttc-nr-demo\`
"; fi)

## Herramientas de Análisis

\`\`\`bash
sudo tcpdump -i any -w traces/capture.pcap
wireshark traces/capture.pcap
tshark -r traces/capture.pcap
nmap -sn 192.168.1.0/24
iperf3 -s
iperf3 -c <ip_servidor>
\`\`\`

## Python

\`\`\`bash
source venv/bin/activate
jupyter notebook
pip install <paquete>
\`\`\`
EOF

    log_message "✓ Documentación inicial creada"
}

# =============================================================================
# Verificación y prueba final
# =============================================================================
verify_installation() {
    log_info "Verificando instalación..."

    # Verificar comandos básicos
    command -v python3 >/dev/null 2>&1 && log_message "✓ Python: $(python3 --version)" || return 1
    command -v git >/dev/null 2>&1 && log_message "✓ Git: $(git --version)" || return 1
    command -v tcpdump >/dev/null 2>&1 && log_message "✓ tcpdump instalado" || log_warning "tcpdump no encontrado"
    command -v wireshark >/dev/null 2>&1 && log_message "✓ Wireshark instalado" || log_warning "Wireshark no encontrado"

    # Verificar NS-3
    if [[ -x "$NS3_DIR/ns3" ]]; then
        log_message "✓ NS-3 launcher encontrado: $NS3_DIR/ns3"
        "$NS3_DIR/ns3" show version 2>/dev/null | head -n 3 || true
    else
        log_error "No se encontró $NS3_DIR/ns3"
        return 1
    fi

    # Verificar entorno virtual
    [[ -d "venv" ]] && log_message "✓ Entorno virtual Python encontrado" || return 1

    # Verificar estructura de directorios
    for d in workspace docs backup results traces scripts notebooks; do
        [[ -d "$d" ]] && log_message "✓ $d encontrado" || log_warning "$d no encontrado"
    done

    # Verificar 5G-LENA si se solicitó
    if [[ "$INSTALL_5GLENA" == "true" ]]; then
        if [[ -d "$NS3_DIR/contrib/nr" ]]; then
            log_message "✓ 5G-LENA instalado"
        else
            log_warning "5G-LENA no encontrado, aunque se solicitó su instalación."
        fi
    else
        if [[ -d "$NS3_DIR/contrib/nr" ]]; then
            log_warning "5G-LENA está presente aunque no se solicitó."
        else
            log_message "✓ 5G-LENA no instalado (según configuración)"
        fi
    fi

    log_message "✓ Verificación completada"
}

run_test() {
    log_info "Ejecutando prueba básica de NS-3..."
    cd "$NS3_DIR" || return 1

    log_info "Ejecutando ejemplo 'first'..."
    if ./ns3 run first > /tmp/ns3_test.log 2>&1; then
        log_message "✓ Ejemplo 'first' ejecutado correctamente"
    else
        log_warning "El ejemplo 'first' falló. Revisa /tmp/ns3_test.log para más detalles."
        return 1
    fi

    if [[ "$INSTALL_5GLENA" == "true" ]]; then
        if ./ns3 show targets | grep -q "cttc-nr-demo"; then
            log_info "Ejecutando ejemplo 'cttc-nr-demo' de 5G-LENA..."
            if ./ns3 run cttc-nr-demo > /tmp/ns3_5g_test.log 2>&1; then
                log_message "✓ Ejemplo 'cttc-nr-demo' ejecutado correctamente"
            else
                log_warning "El ejemplo 'cttc-nr-demo' falló. Revisa /tmp/ns3_5g_test.log"
            fi
        else
            log_warning "No se encontró el ejemplo 'cttc-nr-demo' de 5G-LENA."
        fi
    fi

    return 0
}

# =============================================================================
# Resumen final
# =============================================================================
show_summary() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  INSTALACIÓN COMPLETADA"
    echo "============================================================================="
    echo -e "${NC}"
    echo -e "${GREEN}✓ Sistema actualizado${NC}"
    echo -e "${GREEN}✓ Dependencias del sistema instaladas${NC}"
    echo -e "${GREEN}✓ Herramientas de análisis instaladas${NC}"
    echo -e "${GREEN}✓ NS-3 $NS3_VERSION instalado y configurado${NC}"
    if [[ "$INSTALL_5GLENA" == "true" ]]; then
        echo -e "${GREEN}✓ 5G-LENA instalado${NC}"
    else
        echo -e "${YELLOW}✓ 5G-LENA no instalado (opcional)${NC}"
    fi
    echo -e "${GREEN}✓ Entorno virtual Python creado${NC}"
    echo -e "${GREEN}✓ Git configurado${NC}"
    echo -e "${GREEN}✓ Estructura y documentación creadas${NC}"
    echo
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "1. Reiniciar la terminal o ejecutar: source ~/.bashrc"
    echo "2. Verificar NS-3: ns3 --version && ns3 show version"
    echo "3. Probar ejemplo base: cd ~/ns-$NS3_VERSION && ./ns3 run first"
    echo "4. Activar Python: source venv/bin/activate"
    echo "5. Para Wireshark sin sudo, cerrar sesión y volver a ingresar"
    echo
    echo -e "${GREEN}¡Entorno de investigación listo!${NC}"
}

# =============================================================================
# Función principal
# =============================================================================
main() {
    show_banner

    log_info "Este script requiere sudo para instalar paquetes del sistema."

    check_ubuntu
    check_disk_space || exit 1
    backup_existing_config
    update_system
    install_system_dependencies || exit 1
    setup_git_config || exit 1
    create_basic_structure || exit 1
    install_ns3 || exit 1
    install_5g_lena || exit 1   # Depende de la variable INSTALL_5GLENA
    install_python_dependencies || exit 1
    create_initial_docs || exit 1
    setup_permissions
    verify_installation || exit 1
    run_test || log_warning "La prueba de ejemplo falló, pero la instalación continúa."

    show_summary
}

# Ejecutar la función principal
main "$@"