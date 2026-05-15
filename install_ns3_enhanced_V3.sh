#!/bin/bash
set -u
# =============================================================================
# instalación mejorada — V3 (standalone)
# NS-3 vía paquete ns-allinone-3.47 (https://www.nsnam.org/releases/ns-3-47/)
# Investigación en redes + herramientas de análisis
# Archivo: install_ns3_enhanced_V3.sh
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Versionado centralizado
NS_VERSION="3.47"
NS_ALLINONE_DIR="$HOME/ns-allinone-${NS_VERSION}"
NS3_DIR="${NS_ALLINONE_DIR}/ns-${NS_VERSION}"
NS_ALLINONE_ARCHIVE="ns-allinone-${NS_VERSION}.tar.bz2"
NS_ALLINONE_URL="https://www.nsnam.org/releases/${NS_ALLINONE_ARCHIVE}"
LENA_BRANCH_CANDIDATES=("5g-lena-v4.2.y" "5g-lena-v4.1.y")

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

checkout_5g_lena_branch() {
    local branch
    for branch in "${LENA_BRANCH_CANDIDATES[@]}"; do
        log_info "Probando rama compatible de 5G-LENA: ${branch}..."
        if git checkout -b "${branch}" "origin/${branch}" 2>/dev/null; then
            log_message "✓ Rama ${branch} seleccionada"
            return 0
        fi
    done

    log_error "No se encontró una rama compatible de 5G-LENA para NS-${NS_VERSION}"
    return 1
}

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  ENTORNO DE INVESTIGACIÓN EN REDES — INSTALADOR V3"
    echo "  ns-allinone-3.47 + herramientas de análisis y desarrollo"
    echo "============================================================================="
    echo -e "${NC}"
}

# Función para verificar espacio en disco
check_disk_space() {
    log_info "Verificando espacio en disco..."
    local required_space=8000000  # 8GB en KB
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $required_space ]]; then
        log_error "Espacio insuficiente. Se requieren al menos 8GB libres"
        return 1
    fi
    log_message "✓ Espacio en disco suficiente"
    return 0
}

# Función para backup de configuraciones
backup_existing_config() {
    log_info "Creando backup de configuraciones existentes..."
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
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
    sudo apt update && sudo apt upgrade -y
    log_message "✓ Sistema actualizado"
}

# Función para instalar dependencias del sistema
install_system_dependencies() {
    log_info "Instalando dependencias del sistema..."
    
    # Lista de paquetes requeridos (incluyendo herramientas de análisis)
    PACKAGES=(
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
        # Herramientas de análisis de red
        "wireshark"
        "tcpdump"
        "tshark"
        "nmap"
        "iperf3"
        "netstat-nat"
        "traceroute"
        "mtr"
        # Herramientas adicionales para desarrollo
        "vim"
        "nano"
        "htop"
        "tree"
        "jq"
        # Dependencias adicionales para 5G-LENA
        "sqlite3"
        "libsqlite3-dev"
    )

    for package in "${PACKAGES[@]}"; do
        log_info "Instalando $package..."
        if sudo apt install -y "$package"; then
            log_message "✓ $package instalado"
        else
            log_error "Error instalando $package"
            return 1
        fi
    done

    # Configurar Wireshark para usuarios no-root
    log_info "Configurando Wireshark para uso sin privilegios root..."
    sudo usermod -a -G wireshark "$USER"
    
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
    read -p "Ingrese su nombre completo: " git_name
    read -p "Ingrese su email: " git_email
    
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
    log_info "Creando estructura básica de trabajo..."
    
    # Crear directorios básicos
    BASIC_DIRS=(
        "workspace"
        "docs"
        "backup"
    )
    
    for dir in "${BASIC_DIRS[@]}"; do
        mkdir -p "$dir"
        log_message "✓ Directorio creado: $dir"
    done
    
    # Crear .gitignore básico
    cat > .gitignore << 'EOF'
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
.lock-waf*

# Archivos temporales
*~
.DS_Store
Thumbs.db

# Logs
*.log
logs/
EOF

    log_message "✓ Estructura básica creada"
    return 0
}

# Función para instalar módulo 5G-LENA (versión inline para optimización)
install_5g_lena_module_inline() {
    log_info "Instalando módulo 5G-LENA..."
    
    # Verificar que estemos en el directorio correcto
    if [[ ! -f "ns3" ]]; then
        log_error "No se encuentra en el directorio raíz de NS-3"
        return 1
    fi
    
    # Navegar al directorio contrib
    cd contrib
    
    # Verificar si el módulo ya existe
    if [[ -d "nr" ]]; then
        log_message "✓ Módulo 5G-LENA ya existe"
        cd ..
        return 0
    fi
    
    # Clonar el repositorio de 5G-LENA
    log_info "Clonando repositorio 5G-LENA desde GitLab..."
    if git clone https://gitlab.com/cttc-lena/nr.git; then
        log_message "✓ Repositorio 5G-LENA clonado"
    else
        log_error "Error clonando repositorio 5G-LENA"
        cd ..
        return 1
    fi
    
    # Navegar al directorio del módulo
    cd nr
    
    # Seleccionar rama compatible con NS-3
    if ! checkout_5g_lena_branch; then
        cd ../..
        return 1
    fi
    
    # Regresar al directorio raíz de NS-3
    cd ../..
    
    log_message "✓ Módulo 5G-LENA instalado correctamente"
    return 0
}

# Función para instalar módulo 5G-LENA (versión original como fallback)
install_5g_lena_module() {
    log_info "Instalando módulo 5G-LENA..."
    
    # Verificar que NS-3 esté instalado
    if [[ ! -d "$NS3_DIR" ]]; then
        log_error "NS-3 no encontrado. Debe instalarse primero."
        return 1
    fi
    
    # Navegar al directorio contrib de NS-3
    cd "${NS3_DIR}/contrib"
    
    # Verificar si el módulo ya existe
    if [[ -d "nr" ]]; then
        log_warning "Módulo 5G-LENA ya existe en contrib/nr"
        read -p "¿Desea reinstalar el módulo 5G-LENA? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Eliminando instalación existente..."
            rm -rf nr
        else
            log_info "Usando módulo 5G-LENA existente"
            cd "$NS3_DIR"
            return 0
        fi
    fi
    
    # Clonar el repositorio de 5G-LENA
    log_info "Clonando repositorio 5G-LENA desde GitLab..."
    if git clone https://gitlab.com/cttc-lena/nr.git; then
        log_message "✓ Repositorio 5G-LENA clonado"
    else
        log_error "Error clonando repositorio 5G-LENA"
        return 1
    fi
    
    # Navegar al directorio del módulo
    cd nr
    
    # Seleccionar rama compatible con NS-3
    if ! checkout_5g_lena_branch; then
        return 1
    fi
    
    # Regresar al directorio raíz de NS-3
    cd "$NS3_DIR"
    
    log_message "✓ Módulo 5G-LENA instalado correctamente"
    return 0
}

# Función para reconfigurar NS-3 con módulo 5G-LENA
reconfigure_ns3_with_5g_lena() {
    log_info "Reconfigurando NS-3 con módulo 5G-LENA..."
    
    cd "$NS3_DIR"
    
    # Limpiar build anterior
    log_info "Limpiando build anterior..."
    ./ns3 clean
    rm -rf build/
    rm -rf cmake-cache/
    
    # Reconfigurar NS-3 incluyendo el módulo nr
    log_info "Configurando NS-3 con módulo 5G-LENA..."
    if ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules=core,network,internet,mobility,wifi,mesh,energy,flow-monitor,aodv,dsdv,olsr,applications,csma,point-to-point,wave,nr; then
        log_message "✓ NS-3 configurado con módulo 5G-LENA"
    else
        log_error "Error configurando NS-3 con módulo 5G-LENA"
        return 1
    fi
    
    # Verificar que el módulo nr aparezca en la configuración
    log_info "Verificando que el módulo nr esté incluido..."
    if ./ns3 show config | grep -q "nr"; then
        log_message "✓ Módulo nr detectado en la configuración"
    else
        log_warning "Módulo nr no aparece en la configuración, pero continuando..."
    fi
    
    # Recompilar NS-3 con el módulo 5G-LENA
    log_info "Compilando NS-3 con módulo 5G-LENA (esto puede tomar varios minutos)..."
    local cores=$(nproc)
    log_info "Usando $cores cores para compilación paralela"
    
    if ./ns3 build -j$cores; then
        log_message "✓ NS-3 compilado exitosamente con módulo 5G-LENA"
    else
        log_error "Error compilando NS-3 con módulo 5G-LENA"
        return 1
    fi
    
    return 0
}

# Función para verificar instalación de 5G-LENA
verify_5g_lena_installation() {
    log_info "Verificando instalación de 5G-LENA..."
    
    cd "$NS3_DIR"
    
    # Verificar que el módulo nr esté en la configuración
    if ./ns3 show config | grep -q "nr"; then
        log_message "✓ Módulo nr encontrado en configuración de NS-3"
    else
        log_warning "Módulo nr no aparece en la configuración"
    fi
    
    # Verificar ejemplos disponibles del módulo nr
    log_info "Buscando ejemplos de 5G-LENA disponibles..."
    if ./ns3 show targets | grep -q "cttc-nr"; then
        log_message "✓ Ejemplos de 5G-LENA encontrados"
        log_info "Ejemplos disponibles:"
        ./ns3 show targets | grep "cttc-nr" | head -5
    else
        log_warning "No se encontraron ejemplos de 5G-LENA en targets"
    fi
    
    # Verificar directorio de ejemplos
    if [[ -d "contrib/nr/examples" ]]; then
        local example_count=$(ls contrib/nr/examples/*.cc 2>/dev/null | wc -l)
        log_message "✓ Directorio de ejemplos encontrado con $example_count archivos"
    else
        log_warning "Directorio de ejemplos no encontrado"
    fi
    
    # Intentar ejecutar un ejemplo básico para verificar funcionamiento
    log_info "Intentando ejecutar ejemplo de prueba..."
    if ./ns3 show targets | grep -q "cttc-nr-demo"; then
        log_message "✓ Ejemplo cttc-nr-demo disponible para ejecución"
        log_info "Para ejecutar: ./ns3 run cttc-nr-demo"
    else
        log_info "Para ver ejemplos disponibles: ./ns3 show targets | grep nr"
    fi
    
    return 0
}

# Función para instalar NS-3 con las opciones especificadas
install_ns3() {
    log_info "Instalando NS-3..."
    
    # Verificar si NS-3 ya está instalado
    if command -v ns3 &> /dev/null; then
        log_message "✓ NS-3 ya está instalado: $(ns3 --version)"
        return 0
    fi
    
    # Crear directorio para NS-3
    if [[ -d "$NS_ALLINONE_DIR" ]]; then
        log_warning "Directorio ns-allinone ya existe: $NS_ALLINONE_DIR"
        read -p "¿Desea reinstalar NS-3? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$NS_ALLINONE_DIR"
        else
            log_info "Usando instalación existente"
            return 0
        fi
    fi
    
    # Descargar ns-allinone
    log_info "Descargando ${NS_ALLINONE_ARCHIVE}..."
    cd "$HOME"
    wget "$NS_ALLINONE_URL"
    if [[ ! -f "$NS_ALLINONE_ARCHIVE" ]]; then
        log_error "Error descargando NS-3"
        return 1
    fi
    
    # Extraer ns-allinone y entrar al árbol NS-3
    log_info "Extrayendo ${NS_ALLINONE_ARCHIVE}..."
    tar xjf "$NS_ALLINONE_ARCHIVE"
    cd "$NS3_DIR"
    
    # Instalar módulo 5G-LENA antes de la primera compilación
    log_info "Instalando módulo 5G-LENA antes de la compilación..."
    if ! install_5g_lena_module_inline; then
        log_warning "Error instalando módulo 5G-LENA, continuando con NS-3 base"
        # Configurar solo NS-3 base si falla 5G-LENA
        ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules=core,network,internet,mobility,wifi,mesh,energy,flow-monitor,aodv,dsdv,olsr,applications,csma,point-to-point,wave
    else
        # Configurar NS-3 con módulo 5G-LENA incluido desde el inicio
        log_info "Configurando NS-3 con módulo 5G-LENA..."
        ./ns3 configure --enable-examples --enable-tests --build-profile=optimized --enable-modules=core,network,internet,mobility,wifi,mesh,energy,flow-monitor,aodv,dsdv,olsr,applications,csma,point-to-point,wave,nr
    fi
    
    if [[ $? -ne 0 ]]; then
        log_error "Error configurando NS-3"
        return 1
    fi
    
    # Compilar NS-3 una sola vez con todo incluido
    log_info "Compilando NS-3 con todos los módulos (esto puede tomar varios minutos)..."
    local cores=$(nproc)
    log_info "Usando $cores cores para compilación paralela"
    ./ns3 build -j$cores
    if [[ $? -ne 0 ]]; then
        log_error "Error compilando NS-3"
        return 1
    fi
    
    # Agregar al PATH
    if ! grep -Fq "${NS3_DIR}" ~/.bashrc 2>/dev/null; then
        echo "export PATH=\$PATH:$NS3_DIR" >> ~/.bashrc
    fi
    export PATH="$PATH:$NS3_DIR"
    
    log_message "✓ NS-3 instalado correctamente"
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
    source venv/bin/activate
    
    # Actualizar pip en el entorno virtual
    log_info "Actualizando pip..."
    pip install --upgrade pip --quiet
    
    # Lista de paquetes Python (incluyendo herramientas de análisis)
    PACKAGES=(
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
    
    for package in "${PACKAGES[@]}"; do
        log_info "Instalando $package..."
        if pip install "$package" --quiet; then
            log_message "✓ $package instalado"
        else
            log_error "Error instalando $package"
            return 1
        fi
    done
    
    # Desactivar entorno virtual
    deactivate
    
    log_message "✓ Todas las dependencias Python instaladas en entorno virtual"
    return 0
}

# Función para configurar permisos
setup_permissions() {
    log_info "Configurando permisos..."
    
    # Dar permisos de ejecución a los scripts que existan
    if ls *.py 1> /dev/null 2>&1; then
        chmod +x *.py
    fi
    
    if ls *.sh 1> /dev/null 2>&1; then
        chmod +x *.sh
    fi
    
    # Configurar límites del sistema
    # Evita duplicar entradas en ejecuciones repetidas
    if ! sudo grep -q "^\* soft nofile 65536$" /etc/security/limits.conf; then
        echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf > /dev/null
    fi
    if ! sudo grep -q "^\* hard nofile 65536$" /etc/security/limits.conf; then
        echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf > /dev/null
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
- **NS-3 3.47 (desde ns-allinone-3.47)** - Simulador de redes discreto
- **5G-LENA** - Módulo para simulación de redes 5G NR
- Módulos habilitados: core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point, wave, nr

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

## Estructura Básica
```
├── workspace/           # Área de trabajo para proyectos
├── docs/               # Documentación
├── backup/             # Respaldos
└── venv/              # Entorno virtual Python
```

## Uso Básico

### Activar Entorno Python
```bash
source venv/bin/activate
```

### Verificar NS-3 y 5G-LENA
```bash
ns3 --version
ns3 show version
ns3 show config | grep nr

# Ejecutar ejemplo 5G
ns3 run cttc-nr-demo
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
- Wireshark está configurado para uso sin privilegios root (requiere reiniciar sesión)

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
- **Versión**: 3.47 (ns-allinone)
- **Ubicación**: `~/ns-allinone-3.47/ns-3.47/`
- **Comando**: `ns3`

### Módulos Habilitados
- core, network, internet
- mobility, wifi, mesh
- energy, flow-monitor
- aodv, dsdv, olsr
- applications, csma, point-to-point, wave
- **nr** (5G-LENA para simulación 5G NR)

### Comandos Útiles
```bash
# Ver versión
ns3 --version

# Listar ejemplos
ns3 show examples

# Ejecutar ejemplo básico
ns3 run first

# Ejecutar ejemplo 5G-LENA
ns3 run cttc-nr-demo

# Compilar proyecto
ns3 build

# Limpiar build
ns3 clean
```

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
    if [[ -d "venv" ]]; then
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
    if command -v ns3 &> /dev/null; then
        NS3_VERSION=$(ns3 show version 2>/dev/null | head -n1)
        if [[ -n "$NS3_VERSION" ]] && [[ ! "$NS3_VERSION" =~ "disabled" ]]; then
            log_message "✓ NS-3 encontrado: $NS3_VERSION"
        else
            log_message "✓ NS-3 encontrado en PATH (versión ${NS_VERSION})"
        fi
    else
        # Buscar NS-3 en ubicaciones comunes
        NS3_PATHS=(
            "/usr/local/bin/ns3"
            "/opt/ns-allinone-${NS_VERSION}/ns-${NS_VERSION}/build/ns3"
            "$NS3_DIR/ns3"
            "$NS3_DIR/build/ns3"
            "./ns-allinone-${NS_VERSION}/ns-${NS_VERSION}/ns3"
            "./ns-allinone-${NS_VERSION}/ns-${NS_VERSION}/build/ns3"
        )
        
        NS3_FOUND=false
        for path in "${NS3_PATHS[@]}"; do
            if [[ -f "$path" ]]; then
                log_message "✓ NS-3 encontrado en: $path"
                export PATH="$(dirname "$path"):$PATH"
                NS3_FOUND=true
                break
            fi
        done
        
        if [[ "$NS3_FOUND" == false ]]; then
            log_error "NS-3 no encontrado"
            return 1
        fi
    fi
    
    # Verificar estructura básica
    BASIC_DIRS=("workspace" "docs")
    for dir in "${BASIC_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            log_message "✓ Directorio $dir encontrado"
        else
            log_warning "Directorio $dir no encontrado, creándolo..."
            mkdir -p "$dir"
            if [[ -d "$dir" ]]; then
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
    echo -e "${GREEN}✓ NS-3 3.47 (ns-allinone) instalado y configurado${NC}"
    echo -e "${GREEN}✓ Módulo 5G-LENA instalado y configurado${NC}"
    echo -e "${GREEN}✓ Entorno virtual Python con librerías científicas${NC}"
    echo -e "${GREEN}✓ Git configurado para control de versiones${NC}"
    echo -e "${GREEN}✓ Estructura básica de trabajo creada${NC}"
    echo -e "${GREEN}✓ Documentación generada${NC}"
    echo -e "${GREEN}✓ Permisos configurados${NC}"
    echo -e "${GREEN}✓ Verificación completada${NC}"
    echo
    echo -e "${YELLOW}Próximos pasos para el grupo de investigación:${NC}"
    echo "1. Reiniciar la terminal o ejecutar: source ~/.bashrc"
    echo "2. Leer la documentación: cat README.md"
    echo "3. Ver guía de herramientas: cat docs/TOOLS_GUIDE.md"
    echo "4. Activar entorno Python: source venv/bin/activate"
    echo "5. Verificar NS-3: ns3 --version"
    echo "6. Probar 5G-LENA: ns3 run cttc-nr-demo"
    echo "7. Para Wireshark sin sudo, reiniciar sesión (logout/login)"
    echo
    echo -e "${BLUE}Archivos importantes creados:${NC}"
    echo "- README.md (Documentación principal)"
    echo "- docs/TOOLS_GUIDE.md (Guía de herramientas)"
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

    # Verificar disponibilidad de sudo desde el inicio
    if ! command -v sudo &> /dev/null; then
        log_error "sudo no está disponible en este sistema"
        exit 1
    fi
    
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
    
    # El módulo 5G-LENA ya se instaló durante install_ns3()
    # Solo verificamos que esté correctamente instalado
    log_info "Verificando instalación del módulo 5G-LENA..."
    if [[ ! -d "${NS3_DIR}/contrib/nr" ]]; then
        log_warning "Módulo 5G-LENA no encontrado, instalando como fallback..."
        if ! install_5g_lena_module; then
            log_error "Error instalando módulo 5G-LENA"
            exit 1
        fi
        
        # Reconfigurar NS-3 con módulo 5G-LENA
        if ! reconfigure_ns3_with_5g_lena; then
            log_error "Error reconfigurando NS-3 con módulo 5G-LENA"
            exit 1
        fi
    else
        log_message "✓ Módulo 5G-LENA ya instalado durante la compilación de NS-3"
    fi
    
    # Instalar dependencias Python
    if ! install_python_dependencies; then
        log_error "Error instalando dependencias Python"
        exit 1
    fi
    

    
    # Crear documentación inicial
    log_info "Preparando creación de documentación..."
    log_info "Directorio de trabajo actual: $(pwd)"
    log_info "Usuario actual: $(whoami)"
    log_info "Permisos del directorio: $(ls -ld .)"
    
    if ! create_initial_docs; then
        log_error "Error creando documentación"
        exit 1
    fi
    
    # Verificación adicional después de crear documentación
    log_info "Verificando archivos de documentación creados..."
    if [[ -f "README.md" ]]; then
        log_message "✓ README.md confirmado en $(pwd)/README.md"
        log_info "Tamaño: $(ls -lh README.md | awk '{print $5}')"
    else
        log_error "README.md no encontrado después de la creación"
        log_info "Archivos en directorio actual:"
        ls -la
    fi
    
    # Configurar permisos
    setup_permissions
    
    # Verificar instalación
    if ! verify_installation; then
        log_error "Verificación de instalación falló"
        exit 1
    fi
    
    # Verificar instalación de 5G-LENA
    verify_5g_lena_installation
    
    # Mostrar resumen
    show_summary
}

# Ejecutar función principal
main "$@"
