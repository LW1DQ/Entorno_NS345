#!/bin/bash
# =============================================================================
# Script de Instalación de Herramientas para Investigación en Redes
# Grupo de Investigación - NS-3 3.49 y Herramientas de Análisis
# Adaptado para Ubuntu 26 Desktop
# Versión 5.0.0
# =============================================================================

set -o pipefail
trap 'log_error "Script interrumpido. Saliendo..."; exit 1' INT TERM

# =============================================================================
# Configuración general
# =============================================================================
NS3_VERSION="3.49"
NS3_DIR="$HOME/ns-$NS3_VERSION"
NS3_TARBALL="ns-$NS3_VERSION.tar.bz2"
NS3_URL="https://www.nsnam.org/releases/$NS3_TARBALL"
NS3_MODULES="core,network,internet,mobility,wifi,mesh,energy,flow-monitor,aodv,dsdv,olsr,applications,csma,point-to-point"

# Directorio de trabajo (venv, workspace, docs, README.md, .gitignore).
# Por defecto es el directorio desde el que se ejecuta el script. Si se ejecuta
# desde el clon del repositorio, se usa ~/entorno_ns3 para no sobrescribir el
# README.md ni el .gitignore del repo. Puede forzarse con NS3_WORKDIR=/ruta.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${NS3_WORKDIR:-}" ]]; then
    WORK_DIR="$NS3_WORKDIR"
elif [[ "$(pwd)" == "$SCRIPT_DIR" ]]; then
    WORK_DIR="$HOME/entorno_ns3"
else
    WORK_DIR="$(pwd)"
fi

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para logging
log_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  INSTALACIÓN DE HERRAMIENTAS PARA INVESTIGACIÓN EN REDES"
    echo "  NS-3 $NS3_VERSION, Herramientas de Análisis y Entorno de Desarrollo"
    echo "  (Ubuntu 26 Desktop)"
    echo "============================================================================="
    echo -e "${NC}"
}

# Función para verificar espacio en disco
# Se mide en $HOME, que es donde se instala NS-3 (puede ser otra partición que /).
check_disk_space() {
    log_info "Verificando espacio en disco en $HOME..."
    local required_space=8000000  # 8GB en KB
    local available_space
    available_space=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $required_space ]]; then
        log_error "Espacio insuficiente. Se requieren al menos 8GB libres en $HOME"
        return 1
    fi
    log_message "✓ Espacio en disco suficiente"
    return 0
}

# Función para backup de configuraciones
backup_existing_config() {
    log_info "Creando backup de configuraciones existentes..."
    local backup_dir
    backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    if [[ -f ~/.bashrc ]]; then
        cp ~/.bashrc "$backup_dir/bashrc"
        log_message "✓ Backup de .bashrc creado"
    fi

    if [[ -f ~/.gitconfig ]]; then
        cp ~/.gitconfig "$backup_dir/gitconfig"
        log_message "✓ Backup de .gitconfig creado"
    fi

    echo "$backup_dir" > ~/.last_config_backup
    log_message "✓ Backups guardados en: $backup_dir"
}

# Función para actualizar sistema
update_system() {
    log_info "Actualizando sistema..."
    sudo DEBIAN_FRONTEND=noninteractive apt update && \
        sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
    log_message "✓ Sistema actualizado"
}

# Instala un paquete APT. Si es requerido y falla, devuelve error;
# si es opcional y falla, solo advierte y continúa.
install_apt_package() {
    local package="$1"
    local required="${2:-true}"
    if dpkg -s "$package" >/dev/null 2>&1; then
        log_message "✓ $package ya instalado"
        return 0
    fi
    log_info "Instalando $package..."
    if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$package"; then
        log_message "✓ $package instalado"
        return 0
    fi
    if [[ "$required" == "true" ]]; then
        log_error "Error instalando paquete requerido: $package"
        return 1
    fi
    log_warning "No se pudo instalar el paquete opcional $package. Continuando..."
    return 0
}

# Función para instalar dependencias del sistema
install_system_dependencies() {
    log_info "Instalando dependencias del sistema..."

    # Permitir captura de paquetes a usuarios no-root (grupo wireshark).
    # Sin esto, en modo no interactivo debconf responde "No" y dumpcap
    # queda sin permisos aunque el usuario esté en el grupo.
    echo "wireshark-common wireshark-common/install-setuid boolean true" | \
        sudo debconf-set-selections

    # Paquetes requeridos (si fallan, el script se detiene)
    local required_packages=(
        "python3-venv"
        "build-essential"
        "gcc"
        "g++"
        "python3"
        "python3-pip"
        "python3-dev"
        "git"
        "wget"
        "curl"
        "unzip"
        "tar"
        "bzip2"
        "cmake"
        "pkg-config"
        "libsqlite3-dev"
        "libboost-all-dev"
        "libssl-dev"
        "libxml2-dev"
        "libgtk-3-dev"
        # Herramientas de análisis de red
        "wireshark"
        "tcpdump"
        "tshark"
        "nmap"
        "iperf3"
        "traceroute"
        "mtr"
        # Herramientas adicionales para desarrollo
        "vim"
        "nano"
        "htop"
        "tree"
        "jq"
    )

    # Paquetes opcionales (si fallan, solo se advierte)
    local optional_packages=(
        "libgstreamer1.0-dev"
        "libgstreamer-plugins-base1.0-dev"
        "libgstreamer-plugins-bad1.0-dev"
        "gstreamer1.0-plugins-base"
        "gstreamer1.0-plugins-good"
        "gstreamer1.0-plugins-bad"
        "gstreamer1.0-plugins-ugly"
        "gstreamer1.0-libav"
        "gstreamer1.0-tools"
        "gstreamer1.0-x"
        "gstreamer1.0-alsa"
        "gstreamer1.0-gl"
        "gstreamer1.0-gtk3"
        "gstreamer1.0-qt5"
        "gstreamer1.0-pulseaudio"
        "netstat-nat"
    )

    local package
    for package in "${required_packages[@]}"; do
        install_apt_package "$package" true || return 1
    done

    for package in "${optional_packages[@]}"; do
        install_apt_package "$package" false
    done

    # Configurar Wireshark para usuarios no-root
    log_info "Configurando Wireshark para uso sin privilegios root..."
    if getent group wireshark >/dev/null 2>&1; then
        sudo usermod -a -G wireshark "$USER"
        log_message "✓ Usuario $USER agregado al grupo wireshark"
    else
        log_warning "No existe el grupo wireshark; la captura sin root requerirá configuración manual"
    fi

    log_message "✓ Todas las dependencias del sistema instaladas"
    return 0
}

# Función para configurar Git
setup_git_config() {
    log_info "Configurando Git para control de versiones..."

    # Verificar si Git ya está configurado
    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        log_message "✓ Git ya está configurado"
        log_info "Usuario: $(git config --global user.name)"
        log_info "Email: $(git config --global user.email)"
        return 0
    fi

    # Configuración interactiva de Git
    echo -e "${YELLOW}Configuración de Git para control de versiones:${NC}"
    read -r -p "Ingrese su nombre completo: " git_name
    read -r -p "Ingrese su email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"

    # Configuraciones adicionales recomendadas
    git config --global init.defaultBranch main
    git config --global core.editor nano
    git config --global pull.rebase false
    git config --global core.autocrlf input

    log_message "✓ Git configurado correctamente"
    return 0
}

# Función para crear estructura básica de trabajo
create_basic_structure() {
    log_info "Creando estructura básica de trabajo en $WORK_DIR..."

    # Crear directorios básicos
    local basic_dirs=(
        "workspace"
        "docs"
        "backup"
    )

    local dir
    for dir in "${basic_dirs[@]}"; do
        mkdir -p "$WORK_DIR/$dir"
        log_message "✓ Directorio creado: $dir"
    done

    # Crear .gitignore básico (no se pisa uno existente)
    if [[ -f "$WORK_DIR/.gitignore" ]]; then
        log_info ".gitignore ya existe en $WORK_DIR; se conserva"
    else
        cat > "$WORK_DIR/.gitignore" << 'EOF'
# Archivos de resultados y trazas
*.pcap
*.tr
*.log
*.dat
*.tmp

# Archivos de Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/

# Archivos de NS-3
*.o
*.a
build/
cmake-cache/
.lock-ns3*

# Archivos temporales
*~
.DS_Store
Thumbs.db

# Logs
logs/
EOF
    fi

    log_message "✓ Estructura básica creada"
    return 0
}

# Agrega NS-3 al PATH en ~/.bashrc de forma idempotente.
# Solo elimina las líneas "export PATH=...ns-3.X" que agregaron instaladores
# anteriores; no toca otras líneas del usuario que mencionen ns-3.
add_ns3_to_path() {
    if [[ -f ~/.bashrc ]]; then
        sed -i -E '/^# NS-3 [0-9.]+$/d; /^export PATH=.*ns-3\.[0-9]+\/?$/d' ~/.bashrc
    fi
    {
        echo "# NS-3 $NS3_VERSION"
        echo "export PATH=\$PATH:\$HOME/ns-$NS3_VERSION"
    } >> ~/.bashrc

    # PATH de la sesión actual: quitar rutas a otras versiones de ns-3
    local clean_path
    clean_path=$(echo "$PATH" | tr ':' '\n' | grep -vE '/ns-3\.[0-9]+/?$' | paste -sd:)
    export PATH="$NS3_DIR:$clean_path"
}

# Función para instalar NS-3 con las opciones especificadas
install_ns3() {
    log_info "Instalando NS-3 $NS3_VERSION..."

    # Verificar si NS-3 ya está instalado
    if [[ -x "$NS3_DIR/ns3" ]] && [[ -d "$NS3_DIR/build" ]]; then
        log_message "✓ NS-3 $NS3_VERSION ya está instalado en $NS3_DIR"
        add_ns3_to_path
        return 0
    fi

    if [[ -d "$NS3_DIR" ]]; then
        log_warning "Directorio NS-3 ya existe pero la instalación está incompleta: $NS3_DIR"
        read -r -p "¿Desea reinstalar NS-3? (y/N): " -n 1 reply
        echo
        if [[ $reply =~ ^[Yy]$ ]]; then
            rm -rf "$NS3_DIR"
        else
            log_info "Usando instalación existente"
            add_ns3_to_path
            return 0
        fi
    fi

    # Descargar NS-3
    log_info "Descargando NS-3 $NS3_VERSION..."
    cd "$HOME" || return 1
    rm -f "$NS3_TARBALL"
    if ! wget -O "$NS3_TARBALL" "$NS3_URL"; then
        log_error "Error descargando NS-3 desde $NS3_URL"
        rm -f "$NS3_TARBALL"
        return 1
    fi

    # Extraer NS-3
    log_info "Extrayendo NS-3..."
    if ! tar xjf "$NS3_TARBALL"; then
        log_error "Error extrayendo $NS3_TARBALL"
        return 1
    fi
    cd "$NS3_DIR" || return 1

    # Configurar NS-3
    log_info "Configurando NS-3..."
    if ! ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules="$NS3_MODULES"; then
        log_error "Error configurando NS-3"
        return 1
    fi

    # Compilar NS-3 una sola vez con todo incluido
    log_info "Compilando NS-3 con todos los módulos (esto puede tomar varios minutos)..."
    local cores
    cores=$(nproc)
    log_info "Usando $cores cores para compilación paralela"
    if ! ./ns3 build -j"$cores"; then
        log_error "Error compilando NS-3"
        return 1
    fi

    # Agregar al PATH
    add_ns3_to_path

    # Limpiar el comprimido descargado
    rm -f "$HOME/$NS3_TARBALL"

    log_message "✓ NS-3 instalado correctamente en $NS3_DIR"
    return 0
}

# Función para instalar dependencias Python
install_python_dependencies() {
    log_info "Instalando dependencias Python..."

    # Crear entorno virtual si no existe o está corrupto
    if [[ ! -d "venv" ]] || [[ ! -f "venv/bin/activate" ]]; then
        log_info "Creando entorno virtual Python..."
        # Eliminar directorio corrupto si existe
        if [[ -d "venv" ]]; then
            log_info "Eliminando entorno virtual corrupto..."
            rm -rf venv
        fi

        if python3 -m venv venv; then
            log_message "✓ Entorno virtual creado"
        else
            log_error "Error creando entorno virtual"
            return 1
        fi
    else
        log_message "✓ Entorno virtual ya existe"
    fi

    # Activar entorno virtual
    log_info "Activando entorno virtual..."
    # shellcheck disable=SC1091
    source venv/bin/activate

    # Actualizar pip en el entorno virtual
    log_info "Actualizando pip..."
    pip install --upgrade pip --quiet

    # Lista de paquetes Python (incluyendo herramientas de análisis)
    local packages=(
        "pandas"
        "numpy"
        "matplotlib"
        "seaborn"
        "psutil"
        "scipy"
        "scikit-learn"
        "jupyter"
        "notebook"
        "plotly"
        "networkx"
        "pyshark"
        "scapy"
    )

    local package
    for package in "${packages[@]}"; do
        log_info "Instalando $package..."
        if pip install "$package" --quiet; then
            log_message "✓ $package instalado"
        else
            log_error "Error instalando $package"
            deactivate
            return 1
        fi
    done

    # Registrar versiones exactas para reproducibilidad
    pip freeze > requirements.lock.txt
    log_message "✓ Versiones exactas guardadas en requirements.lock.txt"

    # Desactivar entorno virtual
    deactivate

    log_message "✓ Todas las dependencias Python instaladas en entorno virtual"
    return 0
}

# Función para configurar permisos
setup_permissions() {
    log_info "Configurando permisos..."

    # Dar permisos de ejecución a los scripts del directorio de trabajo
    chmod +x ./*.py 2>/dev/null || true
    chmod +x ./*.sh 2>/dev/null || true

    # Configurar límites del sistema (sin duplicar entradas)
    if ! grep -q "nofile 65536" /etc/security/limits.conf 2>/dev/null; then
        echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf > /dev/null
        echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf > /dev/null
        log_message "✓ Límite de archivos abiertos configurado (65536)"
    else
        log_message "✓ Límite de archivos abiertos ya configurado"
    fi

    log_message "✓ Permisos configurados"
}

# Función para crear documentación inicial
create_initial_docs() {
    log_info "Creando documentación inicial..."

    # Verificar directorio actual
    log_info "Directorio actual: $(pwd)"

    # README principal
    log_info "Creando README.md..."
    cat > README.md << 'EOF'
# Entorno de Investigación en Redes - NS-3

## Descripción
Este entorno proporciona todas las herramientas necesarias para investigación en redes utilizando NS-3, herramientas de análisis y un entorno de desarrollo completo.

## Herramientas Instaladas

### Simulación
- **NS-3 3.49** - Simulador de redes de eventos discretos
- Ubicación: `~/ns-3.49/`
- Módulos habilitados: core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point

### Análisis de Red
- **Wireshark/tshark** - Análisis de tráfico de red
- **tcpdump** - Captura de paquetes
- **nmap** - Escaneo de red
- **iperf3** - Medición de rendimiento
- **mtr** - Diagnóstico de red

### Desarrollo
- **Python 3** con entorno virtual
- **Git** configurado para control de versiones
- Librerías científicas: pandas, numpy, matplotlib, seaborn, scipy, scikit-learn, jupyter
- Versiones exactas registradas en `requirements.lock.txt`

## Estructura Básica
```
├── workspace/              # Área de trabajo para proyectos
├── docs/                   # Documentación
├── backup/                 # Respaldos
├── venv/                   # Entorno virtual Python
└── requirements.lock.txt   # Versiones exactas de los paquetes Python
```

## Uso Básico

### Activar Entorno Python
```bash
source venv/bin/activate
```

### Verificar NS-3
```bash
ns3 show profile
ns3 show config

# Ejecutar ejemplo básico
ns3 run first
```

### Herramientas de Red
```bash
# Capturar tráfico
sudo tcpdump -i any -w capture.pcap

# Analizar con Wireshark
wireshark capture.pcap

# Escanear red
nmap -sn 192.168.1.0/24

# Medir rendimiento
iperf3 -s  # servidor
iperf3 -c <ip_servidor>  # cliente
```

## Configuración Git
El script configura Git automáticamente. Para verificar:
```bash
git config --global --list
```

## Notas para el Grupo de Investigación
- Cada investigador puede crear sus propios scripts de simulación en `workspace/`
- Usar Git para control de versiones de proyectos individuales
- El entorno virtual Python está listo para instalar librerías adicionales según necesidades específicas
- Wireshark está configurado para uso sin privilegios root (requiere cerrar sesión y volver a entrar)

## Soporte
Este entorno está diseñado para ser flexible y adaptarse a diferentes tipos de investigación en redes.
EOF

    # Verificar que README.md se creó
    if [[ -f "README.md" ]]; then
        log_message "✓ README.md creado exitosamente"
    else
        log_error "Error: README.md no se pudo crear"
        return 1
    fi

    # Crear directorio docs si no existe
    mkdir -p docs
    log_info "Creando docs/TOOLS_GUIDE.md..."

    # Guía de herramientas
    cat > docs/TOOLS_GUIDE.md << 'EOF'
# Guía de Herramientas Instaladas

## NS-3 Network Simulator

### Información Básica
- **Versión**: 3.49
- **Ubicación**: `~/ns-3.49/`
- **Comando**: `ns3`

### Módulos Habilitados
- core, network, internet
- mobility, wifi, mesh
- energy, flow-monitor
- aodv, dsdv, olsr
- applications, csma, point-to-point

### Comandos Útiles
```bash
# Ver perfil de compilación y configuración
ns3 show profile
ns3 show config

# Listar programas compilables/ejecutables
ns3 show targets

# Ejecutar ejemplo básico
ns3 run first

# Compilar proyecto
ns3 build

# Limpiar build
ns3 clean
```

> Nota: `ns3 show version` solo informa la versión si NS-3 se configuró con
> `--enable-build-version`; en caso contrario indica que está deshabilitado.
> La versión instalada se identifica por el directorio `~/ns-3.49/`.

## Herramientas de Análisis de Red

### Wireshark
```bash
# Interfaz gráfica
wireshark

# Línea de comandos
tshark -i eth0 -w capture.pcap

# Analizar archivo
tshark -r capture.pcap
```

### tcpdump
```bash
# Captura básica
sudo tcpdump -i any -w capture.pcap

# Filtrar por puerto
sudo tcpdump -i any port 80

# Ver en tiempo real
sudo tcpdump -i any -n
```

### nmap
```bash
# Escaneo básico
nmap 192.168.1.1

# Escaneo de red
nmap -sn 192.168.1.0/24

# Escaneo de puertos
nmap -p 1-1000 192.168.1.1
```

### iperf3
```bash
# Servidor
iperf3 -s

# Cliente
iperf3 -c <servidor_ip>

# UDP test
iperf3 -c <servidor_ip> -u
```

## Python y Librerías Científicas

### Activar Entorno
```bash
source venv/bin/activate
```

### Librerías Disponibles
- **pandas**: Manipulación de datos
- **numpy**: Computación numérica
- **matplotlib**: Gráficos
- **seaborn**: Visualización estadística
- **scipy**: Computación científica
- **scikit-learn**: Machine learning
- **jupyter**: Notebooks interactivos
- **networkx**: Análisis de grafos
- **pyshark**: Análisis de paquetes
- **scapy**: Manipulación de paquetes

### Reproducir el mismo entorno en otra máquina
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.lock.txt
```

### Instalar Librerías Adicionales
```bash
source venv/bin/activate
pip install <libreria>
```

## Git

### Configuración
```bash
# Ver configuración
git config --global --list

# Cambiar configuración
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### Comandos Básicos
```bash
# Inicializar repositorio
git init

# Agregar archivos
git add .

# Commit
git commit -m "Mensaje"

# Ver estado
git status

# Ver historial
git log --oneline
```

## Tips de Uso

### Para Simulaciones Largas
```bash
# Usar screen o tmux
screen -S simulacion
# o
tmux new -s simulacion
```

### Monitoreo del Sistema
```bash
# Ver procesos
htop

# Uso de disco
df -h

# Espacio de directorio
du -sh *
```

### Backup de Resultados
```bash
# Crear backup con fecha
tar -czf backup_$(date +%Y%m%d).tar.gz workspace/

# Mover a directorio backup
mv backup_*.tar.gz backup/
```
EOF

    # Verificar que TOOLS_GUIDE.md se creó
    if [[ -f "docs/TOOLS_GUIDE.md" ]]; then
        log_message "✓ docs/TOOLS_GUIDE.md creado exitosamente"
    else
        log_error "Error: docs/TOOLS_GUIDE.md no se pudo crear"
        return 1
    fi

    # Verificar archivos finales
    log_info "Archivos de documentación creados:"
    if [[ -f "README.md" ]]; then
        log_info "  - README.md ($(wc -l < README.md) líneas)"
    fi
    if [[ -f "docs/TOOLS_GUIDE.md" ]]; then
        log_info "  - docs/TOOLS_GUIDE.md ($(wc -l < docs/TOOLS_GUIDE.md) líneas)"
    fi

    log_message "✓ Documentación inicial creada"
    return 0
}

# Función para verificar instalación
verify_installation() {
    log_info "Verificando instalación..."

    # Verificar Python
    if command -v python3 &> /dev/null; then
        log_message "✓ Python 3: $(python3 --version)"
    else
        log_error "Python 3 no encontrado"
        return 1
    fi

    # Verificar pip
    if command -v pip3 &> /dev/null; then
        log_message "✓ pip3: $(pip3 --version)"
    else
        log_error "pip3 no encontrado"
        return 1
    fi

    # Verificar entorno virtual
    if [[ -f "venv/bin/activate" ]]; then
        log_message "✓ Entorno virtual Python encontrado"
    else
        log_error "Entorno virtual Python no encontrado"
        return 1
    fi

    # Verificar Git
    if command -v git &> /dev/null; then
        log_message "✓ Git: $(git --version)"
    else
        log_error "Git no encontrado"
        return 1
    fi

    # Verificar Wireshark
    if command -v wireshark &> /dev/null; then
        log_message "✓ Wireshark instalado"
    else
        log_warning "Wireshark no encontrado"
    fi

    # Verificar tcpdump
    if command -v tcpdump &> /dev/null; then
        log_message "✓ tcpdump instalado"
    else
        log_warning "tcpdump no encontrado"
    fi

    # Verificar NS-3
    if [[ -x "$NS3_DIR/ns3" ]] && [[ -d "$NS3_DIR/build" ]]; then
        log_message "✓ NS-3 $NS3_VERSION encontrado en $NS3_DIR"
    else
        log_error "NS-3 $NS3_VERSION no encontrado en $NS3_DIR"
        return 1
    fi

    # Verificar estructura básica
    local basic_dirs=("workspace" "docs")
    local dir
    for dir in "${basic_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_message "✓ Directorio $dir encontrado"
        else
            log_warning "Directorio $dir no encontrado, creándolo..."
            if mkdir -p "$dir"; then
                log_message "✓ Directorio $dir creado"
            else
                log_error "No se pudo crear directorio $dir"
                return 1
            fi
        fi
    done

    log_message "✓ Verificación completada exitosamente"
    return 0
}

# Prueba funcional: ejecuta el ejemplo 'first' de NS-3
run_test() {
    log_info "Ejecutando prueba básica de NS-3 (ejemplo 'first')..."
    local log_file="$WORK_DIR/backup/ns3_first_test.log"
    if (cd "$NS3_DIR" && ./ns3 run first) > "$log_file" 2>&1; then
        log_message "✓ Ejemplo 'first' ejecutado correctamente"
        return 0
    fi
    log_warning "El ejemplo 'first' falló. Revise $log_file"
    return 1
}

# Función para mostrar resumen
show_summary() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  INSTALACIÓN COMPLETADA"
    echo "============================================================================="
    echo -e "${NC}"
    echo -e "${GREEN}✓ Sistema actualizado${NC}"
    echo -e "${GREEN}✓ Dependencias del sistema instaladas${NC}"
    echo -e "${GREEN}✓ Herramientas de análisis instaladas (Wireshark, tcpdump, nmap, iperf3)${NC}"
    echo -e "${GREEN}✓ NS-3 $NS3_VERSION instalado y configurado en $NS3_DIR${NC}"
    echo -e "${GREEN}✓ Entorno virtual Python con librerías científicas${NC}"
    echo -e "${GREEN}✓ Git configurado para control de versiones${NC}"
    echo -e "${GREEN}✓ Estructura básica de trabajo creada en $WORK_DIR${NC}"
    echo -e "${GREEN}✓ Documentación generada${NC}"
    echo -e "${GREEN}✓ Permisos configurados${NC}"
    echo -e "${GREEN}✓ Verificación completada${NC}"
    echo
    echo -e "${YELLOW}Próximos pasos para el grupo de investigación:${NC}"
    echo "1. Reiniciar la terminal o ejecutar: source ~/.bashrc"
    echo "2. Ir al directorio de trabajo: cd $WORK_DIR"
    echo "3. Leer la documentación: cat README.md"
    echo "4. Ver guía de herramientas: cat docs/TOOLS_GUIDE.md"
    echo "5. Activar entorno Python: source venv/bin/activate"
    echo "6. Verificar NS-3: ns3 show config"
    echo "7. Probar un ejemplo: ns3 run first"
    echo "8. Para Wireshark sin sudo, cerrar sesión y volver a entrar"
    echo
    echo -e "${BLUE}Archivos importantes creados en $WORK_DIR:${NC}"
    echo "- README.md (Documentación principal)"
    echo "- docs/TOOLS_GUIDE.md (Guía de herramientas)"
    echo "- requirements.lock.txt (Versiones exactas de Python)"
    echo "- workspace/ (Área de trabajo para proyectos)"
    echo "- .gitignore (Configuración de Git)"
    echo
    echo -e "${GREEN}¡Entorno de investigación listo!${NC}"
    echo -e "${CYAN}Cada investigador puede crear sus proyectos en workspace/${NC}"
}

# Función principal
main() {
    show_banner

    log_info "Este script requiere permisos de sudo para algunas operaciones."
    log_info "Se le solicitará la contraseña cuando sea necesario."

    # Verificar que estamos en Ubuntu
    if [[ ! -f /etc/os-release ]] || ! grep -q "Ubuntu" /etc/os-release; then
        log_error "Este script está diseñado para Ubuntu"
        exit 1
    fi

    # Informar la versión de Ubuntu detectada (el script está pensado para Ubuntu 26 Desktop,
    # pero continúa igual en otras versiones ya que solo depende de paquetes estándar de apt)
    local ubuntu_version
    ubuntu_version=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    if [[ "$ubuntu_version" == "26."* ]]; then
        log_message "✓ Ubuntu $ubuntu_version detectado (versión objetivo de este script)"
    else
        log_warning "Ubuntu $ubuntu_version detectado. El script fue adaptado para Ubuntu 26 Desktop, pero se intentará continuar."
    fi

    # Directorio de trabajo
    if ! mkdir -p "$WORK_DIR" || ! cd "$WORK_DIR"; then
        log_error "No se pudo usar el directorio de trabajo $WORK_DIR"
        exit 1
    fi
    log_info "Directorio de trabajo: $WORK_DIR"

    # Verificar espacio en disco
    if ! check_disk_space; then
        exit 1
    fi

    # Crear backup de configuraciones
    backup_existing_config

    # Actualizar sistema
    update_system

    # Instalar dependencias del sistema
    if ! install_system_dependencies; then
        log_error "Error instalando dependencias del sistema"
        exit 1
    fi

    # Configurar Git
    if ! setup_git_config; then
        log_error "Error configurando Git"
        exit 1
    fi

    # Crear estructura básica
    if ! create_basic_structure; then
        log_error "Error creando estructura básica"
        exit 1
    fi

    # Instalar NS-3 con las opciones especificadas
    if ! install_ns3; then
        log_error "Error instalando NS-3"
        exit 1
    fi

    # install_ns3 cambia de directorio: volver al directorio de trabajo
    cd "$WORK_DIR" || exit 1

    # Instalar dependencias Python
    if ! install_python_dependencies; then
        log_error "Error instalando dependencias Python"
        exit 1
    fi

    # Crear documentación inicial
    if ! create_initial_docs; then
        log_error "Error creando documentación"
        exit 1
    fi

    # Configurar permisos
    setup_permissions

    # Verificar instalación
    if ! verify_installation; then
        log_error "Verificación de instalación falló"
        exit 1
    fi

    # Prueba funcional
    run_test || log_warning "La prueba de ejemplo falló, pero la instalación continúa."

    # Mostrar resumen
    show_summary
}

# Ejecutar función principal
main "$@"
