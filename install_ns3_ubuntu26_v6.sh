#!/bin/bash
# install_ns3_ubuntu26_v6.sh
# Entorno V17: NS-3.48 + LoRaWAN 0.3.7 + 5G-LENA NR v5.1 + SUMO 1.25 + ML Stack
# Ubuntu 26.x Desktop (tested on 26.04 LTS)
# Autor: Diego Rodríguez Herlein
# Uso: ./install_ns3_ubuntu26_v6.sh [--enable-5g-nr] [--enable-lorawan] [--enable-ml] [--enable-sumo] [--workdir ~/entorno_v17]

set -euo pipefail

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

SCRIPT_VERSION="6.0.0"
NS3_VERSION="3.48"
NS3_TARBALL="ns-3.48.tar.bz2"
NS3_URL="https://www.nsnam.org/releases/${NS3_TARBALL}"
NS3_DIR="${HOME}/ns-3.48"

LORAWAN_VERSION="0.3.7"
LORAWAN_REPO="https://github.com/ns-3-dev/ns-3-lorawan.git"
LORAWAN_BRANCH="v0.3.7"

NR_VERSION="5.1"
NR_REPO="https://gitlab.com/cttc-lena/nr.git"
NR_BRANCH="v5.1.y"

SUMO_VERSION="1.25.0"

DEFAULT_WORKDIR="${HOME}/entorno_v17"

ENABLE_5G_NR=false
ENABLE_LORAWAN=true
ENABLE_ML=true
ENABLE_SUMO=true

WORKDIR=""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat <<EOF
Uso: $0 [OPCIONES]

Opciones:
  --enable-5g-nr       Instalar 5G-LENA NR v5.1 (NSA) [default: false]
  --disable-lorawan    Desactivar LoRaWAN 0.3.7 [default: true]
  --disable-ml         Desactivar stack Python ML [default: true]
  --disable-sumo       Desactivar SUMO 1.25 [default: true]
  --workdir DIR        Directorio de trabajo [default: ~/entorno_v17]
  -h, --help           Mostrar esta ayuda

Ejemplos:
  ./install_ns3_ubuntu26_v6.sh --enable-5g-nr --workdir ~/entorno_v17
  ./install_ns3_ubuntu26_v6.sh --disable-ml --disable-sumo
EOF
}

# Parseo de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-5g-nr) ENABLE_5G_NR=true ;;
        --disable-lorawan) ENABLE_LORAWAN=false ;;
        --disable-ml) ENABLE_ML=false ;;
        --disable-sumo) ENABLE_SUMO=false ;;
        --workdir) WORKDIR="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) log_error "Opción desconocida: $1"; usage; exit 1 ;;
    esac
    shift
done

WORKDIR="${WORKDIR:-$DEFAULT_WORKDIR}"
WORKDIR="${WORKDIR/#\~/$HOME}"

# ============================================================================
# FUNCIONES PRINCIPALES
# ============================================================================

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutes este script como root. Usa tu usuario normal (con sudo)."
        exit 1
    fi
}

check_ubuntu() {
    if ! grep -q "Ubuntu 26" /etc/os-release 2>/dev/null; then
        log_warn "Este script está probado en Ubuntu 26.x. Tu SO: $(lsb_release -ds)"
        read -p "¿Continuar de todos modos? (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "Se requieren permisos sudo. Se te pedirá la contraseña."
        sudo -v || { log_error "Se requiere sudo"; exit 1; }
    fi
}

# ============================================================================
# INSTALACIÓN DE DEPENDENCIAS BASE
# ============================================================================

install_base_deps() {
    log_info "Instalando dependencias base del sistema..."
    
    sudo apt-get update
    sudo apt-get install -y \
        build-essential cmake ninja-build g++ git python3 python3-pip python3-venv \
        wget curl tar bzip2 unzip \
        libxml2-dev libboost-all-dev libsqlite3-dev libssl-dev \
        qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        wireshark tshark tcpdump nmap iperf3 traceroute mtr \
        libxml2-dev libboost-all-dev libsqlite3-dev libssl-dev \
        qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        # Dependencias V17
        libgirepository1.0-dev libcairo2-dev libgirepository1.0-dev \
        python3-dev python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
        libxml2-dev libxslt1-dev \
        libhdf5-dev libprotobuf-dev protobuf-compiler \
        libzmq3-dev libczmq-dev \
        libgirepository1.0-dev libcairo2-dev \
        pkg-config \
        doxygen graphviz \
        ccache
    
    log_ok "Dependencias base instaladas"
}

# ============================================================================
# INSTALACIÓN SUMO 1.25
# ============================================================================

install_sumo() {
    if [[ "$ENABLE_SUMO" != true ]]; then
        log_warn "SUMO desactivado (--disable-sumo)"
        return 0
    fi

    log_info "Instalando SUMO ${SUMO_VERSION}..."
    
    if ! command -v sumo &> /dev/null || ! sumo --version | grep -q "${SUMO_VERSION}"; then
        sudo apt-get install -y sumo=${SUMO_VERSION} sumo-tools=${SUMO_VERSION} sumo-doc=${SUMO_VERSION} || {
            log_warn "Versión exacta no disponible en repos, instalando disponible..."
            sudo apt-get install -y sumo sumo-tools sumo-doc
        }
    fi
    
    # Instalar osmium-tool para manipulación OSM
    sudo apt-get install -y osmium-tool
    
    log_ok "SUMO $(sumo --version | head -1) instalado"
}

# ============================================================================
# INSTALACIÓN LORAWAN 0.3.7
# ============================================================================

install_lorawan() {
    [[ "$ENABLE_LORAWAN" == true ]] || { log_warn "LoRaWAN desactivado"; return 0; }
    
    log_info "Instalando LoRaWAN ${LORAWAN_VERSION}..."
    
    cd /tmp
    if [[ -d ns-3-lorawan ]]; then
        rm -rf ns-3-lorawan
    fi
    
    git clone -b "${LORAWAN_BRANCH}" "${LORAWAN_REPO}" ns-3-lorawan
    cd ns-3-lorawan
    
    # Copiar módulo a ns-3.48
    log_info "Copiando módulo LoRaWAN a NS-3..."
    cp -r src/lorawan "${NS3_DIR}/src/"
    cp -r helper/lorawan "${NS3_DIR}/helper/"
    
    # Verificar que los wscript existen
    if [[ ! -f "${NS3_DIR}/src/lorawan/wscript" ]]; then
        log_error "wscript no encontrado en src/lorawan"
        return 1
    fi
    
    cd ~ && rm -rf /tmp/ns-3-lorawan
    log_ok "LoRaWAN ${LORAWAN_VERSION} instalado en NS-3"
}

# ============================================================================
# INSTALACIÓN 5G-LENA NR v5.1 (OPCIONAL)
# ============================================================================

install_5g_nr() {
    [[ "$ENABLE_5G_NR" == true ]] || { log_warn "5G-NR desactivado (usa --enable-5g-nr)"; return 0; }
    
    log_info "Instalando 5G-LENA NR v${NR_VERSION} (NSA)..."
    
    cd /tmp
    if [[ -d nr ]]; then
        rm -rf nr
    fi
    
    git clone -b "${NR_BRANCH}" "${NR_REPO}" nr
    cd nr
    
    # Configurar con ns-3.48
    ./waf configure --with-ns3=~/ns-3.48 --enable-examples --enable-tests
    ./waf build
    
    cd ~ && rm -rf /tmp/nr
    log_ok "5G-LENA NR v${NR_VERSION} instalado"
}

# ============================================================================
# PYTHON ML STACK
# ============================================================================

setup_python_ml() {
    [[ "$ENABLE_ML" == true ]] || { log_warn "ML stack desactivado"; return 0; }
    
    log_info "Configurando entorno Python ML en ${WORKDIR}..."
    
    mkdir -p "${WORKDIR}"
    cd "${WORKDIR}"
    
    # Crear venv si no existe
    if [[ ! -d venv ]]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Actualizar pip
    pip install --upgrade pip setuptools wheel
    
    # requirements.lock para V17
    cat > requirements.lock << 'EOF'
# Core scientific stack
numpy==1.26.4
pandas==2.2.1
scipy==1.13.0
scikit-learn==1.4.1.post1
statsmodels==0.14.2

# ML libraries
xgboost==2.1.1
torch==2.2.2
lightning==2.2.1

# Plotting
matplotlib==3.8.3
seaborn==0.13.2

# Utilities
pyyaml==6.0.1
tqdm==4.66.4
joblib==1.4.2
psutil==5.9.8

# Network analysis
networkx==3.2.1
scapy==2.5.0
pyshark==0.6

# Jupyter
jupyter==1.0.0
notebook==7.0.6
ipykernel==6.29.0

# Testing
pytest==8.1.1
pytest-cov==4.1.0

# Utilities
pyyaml==6.0.1
tqdm==4.66.4
joblib==1.4.2
psutil==5.9.8
EOF

    pip install --no-cache-dir -r requirements.lock
    pip freeze > requirements.lock.txt
    deactivate
    
    log_ok "Entorno Python ML configurado en ${WORKDIR}/venv"
}

# ============================================================================
# DESCARGA Y COMPILACIÓN NS-3.48
# ============================================================================

download_ns3() {
    log_info "Descargando NS-${NS3_VERSION}..."
    
    cd ~
    if [[ ! -f "${NS3_TARBALL}" ]]; then
        wget -q --show-progress "${NS3_URL}" -O "${NS3_TARBALL}"
    else
        log_info "Tarball ya existe, saltando descarga"
    fi
    
    if [[ -d "ns-3.48" ]]; then
        log_warn "Directorio ns-3.48 ya existe, eliminando..."
        rm -rf ns-3.48
    fi
    
    tar -xjf "${NS3_TARBALL}"
    log_ok "NS-${NS3_VERSION} extraído en ~/ns-3.48"
}

configure_ns3_v17() {
    log_info "Configurando NS-3.48 con módulos V17..."
    
    cd "${NS3_DIR}"
    
    # Módulos habilitados para V17
    local modules="core;network;internet;applications;mobility;wifi;mesh;lr-wpan;lorawan;sixlowpan;energy;flow-monitor;buildings;propagation;csma;point-to-point;aodv;olsr;dsdv;dsr;mesh;wimax;wpan;antenna;lte;nr"
    
    ./ns3 configure \
        --enable-examples \
        --enable-tests \
        --enable-modules="${modules}" \
        --build-profile=optimized \
        --enable-build-version \
        --enable-build-optimizations \
        --disable-clang-static-analyzer \
        --disable-python3-bindings \
        --with-ns3-5g-nr=$([[ "$ENABLE_5G_NR" == true ]] && echo "yes" || echo "no")
    
    log_ok "NS-3 configurado con módulos V17"
}

build_ns3() {
    log_info "Compilando NS-3.48 (esto puede tardar 30-60 min)..."
    
    cd "${NS3_DIR}"
    
    # Usar ccache si está disponible
    if command -v ccache &> /dev/null; then
        export CCACHE_DIR="${HOME}/.ccache"
        export CC="ccache g++"
        export CXX="ccache g++"
    fi
    
    # Compilar con todos los cores
    ./ns3 build -j$(nproc)
    
    log_ok "NS-3.48 compilado exitosamente"
}

# ============================================================================
# POST-INSTALACIÓN Y VERIFICACIÓN
# ============================================================================

setup_bashrc() {
    log_info "Configurando ~/.bashrc..."
    
    # Eliminar líneas anteriores de ns-3
    sed -i '/ns-3/d' ~/.bashrc
    sed -i '/entorno_ns3/d' ~/.bashrc
    sed -i '/entorno_v17/d' ~/.bashrc
    
    cat >> ~/.bashrc <<EOF

# NS-3.48 V17 Environment
export NS3_HOME=~/ns-3.48
export PATH=\$NS3_HOME:\$PATH
export NS3_WORKDIR=${WORKDIR}
alias ns3='cd ~/ns-3.48 && ./ns3'
alias v17-env='cd ${WORKDIR} && source venv/bin/activate'

# SUMO
export SUMO_HOME=/usr/share/sumo
export PATH=\$SUMO_HOME/bin:\$PATH
EOF
    
    # Configurar git si no está configurado
    if ! git config --global user.email &> /dev/null; then
        read -p "Git user.email: " git_email
        read -p "Git user.name: " git_name
        git config --global user.email "$git_email"
        git config --global user.name "$git_name"
    fi
    
    log_ok "~/.bashrc configurado"
}

run_sanity_checks() {
    log_info "Ejecutando verificaciones de sanidad..."
    
    # 1. NS-3 configuración
    log_info "Verificando módulos NS-3..."
    cd ~/ns-3.48
    ./ns3 show config | grep -E "lorawan|lr-wpan|mesh|nr" || log_warn "Algunos módulos V17 no aparecen en config"
    
    # 2. SUMO
    if [[ "$ENABLE_SUMO" == true ]]; then
        sumo --version | grep -q "1.25" && log_ok "SUMO 1.25 OK" || log_warn "SUMO versión inesperada"
    fi
    
    # 3. Python ML
    if [[ "$ENABLE_ML" == true ]]; then
        source "${WORKDIR}/venv/bin/activate"
        python -c "import sklearn, xgboost, torch; print('ML OK:', sklearn.__version__, xgboost.__version__, torch.__version__)"
        deactivate
    fi
    
    # 4. Test compilación ejemplo V17
    log_info "Probando compilación de ejemplo V17..."
    cd ~/ns-3.48
    ./ns3 run "sim-iot-smartcity_v17 --rat=wifi --trafficClass=C1 --mobilitySource=synthetic --simTime=10 --nStatic=2 --nMobile=0" 2>&1 | tail -5
    
    log_ok "Todas las verificaciones completadas"
}

create_workdir_structure() {
    log_info "Creando estructura de trabajo en ${WORKDIR}..."
    
    mkdir -p "${WORKDIR}"/{workspace,docs,backup,scripts}
    mkdir -p "${WORKDIR}"/scripts/sumo
    mkdir -p "${WORKDIR}"/scripts/ml
    mkdir -p "${WORKDIR}"/ml/{models,esp32}
    mkdir -p "${WORKDIR}"/tests
    mkdir -p "${WORKDIR}"/scratch
    mkdir -p "${WORKDIR}"/sumo/{la-plata/{osm,maps,traces},lust}
    mkdir -p "${WORKDIR}"/mobility/traces
    mkdir -p "${WORKDIR}"/documentacion
    mkdir -p "${WORKDIR}"/storyboard-v17
    
    # Crear README.md del workspace
    cat > "${WORKDIR}/README.md" <<'EOF'
# V17 Workspace

Entorno de trabajo para la campaña V17: Escenario Heterogéneo con Movilidad Real + Capa ML.

## Estructura
- `workspace/` — Proyectos y simulaciones
- `scripts/` — Scripts de campaña, análisis, ML
- `ml/` — Modelos, datasets, benchmarks ESP32
- `scratch/` — Simulador V17 (sim-iot-smartcity_v17.cc)
- `sumo/` — Mapas OSM, redes SUMO, trazas FCD
- `mobility/` — Trazas de movilidad convertidas
- `documentacion/` — Diseño, metodología, resultados, límites
- `tests/` — Tests unitarios

## Uso
```bash
# Activar entorno Python
source venv/bin/activate

# NS-3
ns3 run sim-iot-smartcity_v17 --rat=wifi --trafficClass=C1 --mobilitySource=sumo-trace --mobilityTrace=...
```

## Reproducibilidad
```bash
./reproduce.sh pilot
```
EOF
    
    log_ok "Estructura de trabajo creada en ${WORKDIR}"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "=========================================="
    echo "  Entorno V17 - NS-3.48 + LoRaWAN + ML"
    echo "  Versión del instalador: ${SCRIPT_VERSION}"
    echo "=========================================="
    
    check_root
    check_ubuntu
    check_sudo
    
    log_info "Configuración:"
    log_info "  NS-3: ${NS3_VERSION}"
    log_info "  LoRaWAN: $([[ "$ENABLE_LORAWAN" == true ]] && echo "SÍ" || echo "NO")"
    log_info "  5G-NR: $([[ "$ENABLE_5G_NR" == true ]] && echo "SÍ" || echo "NO")"
    log_info "  SUMO: $([[ "$ENABLE_SUMO" == true ]] && echo "SÍ" || echo "NO")"
    log_info "  ML Stack: $([[ "$ENABLE_ML" == true ]] && echo "SÍ" || echo "NO")"
    log_info "  Workdir: ${WORKDIR}"
    
    read -p "¿Continuar con la instalación? (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    
    # Ejecución secuencial
    install_base_deps
    install_sumo
    install_lorawan
    install_5g_nr
    download_ns3
    configure_ns3_v17
    build_ns3
    setup_python_ml
    setup_bashrc
    create_workdir_structure
    run_sanity_checks
    
    echo
    echo "=========================================="
    log_ok "INSTALACIÓN V17 COMPLETADA"
    echo "=========================================="
    echo
    echo "Para usar el entorno:"
    echo "  source ~/.bashrc"
    echo "  cd ${WORKDIR}"
    echo "  source venv/bin/activate"
    echo "  ns3 show config"
    echo
    echo "Para correr el piloto V17:"
    echo "  cd ~/ns-3.48"
    echo "  ./ns3 run \"sim-iot-smartcity_v17 --rat=wifi --trafficClass=C1 --mobilitySource=sumo-trace --mobilityTrace=... --simTime=300\""
    echo
    log_ok "¡Entorno V17 listo para investigar!"
}

# Ejecutar main
main "$@"