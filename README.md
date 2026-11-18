# Entorno de Investigación en Redes — NS-3

Instalador automatizado para Ubuntu que configura un entorno completo de investigación en redes: **NS-3 3.48 (LTS)**, **LoRaWAN 0.3.7**, **5G-LENA NR v5.1 (opcional)**, **SUMO 1.25**, **osmium-tool**, herramientas de análisis de tráfico y un **stack Python científico completo** (scikit-learn, xgboost, PyTorch, Lightning, ASlib/COSELECT) en entorno virtual.

> **Versión actual:** v6.0.0 — `install_ns3_ubuntu26_v6.sh` (NS-3 3.48 LTS + V17).
> Ver [CHANGELOG.md](./CHANGELOG.md) para el detalle de cambios respecto de versiones anteriores.
> Adaptado y orientado a **Ubuntu 26.x Desktop**; en otras versiones de Ubuntu continúa con advertencia.

## Requisitos

- **Ubuntu** (idealmente 26.x)
- **≥ 15 GB** libres en la partición de `$HOME` (allí se instala NS-3 + dependencias)
- **sudo** disponible
- Conexión a Internet (descarga de `ns-3.48.tar.bz2` desde nsnam.org, clonación LoRaWAN/5G-LENA/SUMO, paquetes APT/pip)

## Instalación rápida

```bash
git clone https://github.com/LW1DQ/Entorno_NS345.git
cd Entorno_NS345
chmod +x install_ns3_ubuntu26_v6.sh
./install_ns3_ubuntu26_v6.sh --enable-5g-nr --workdir ~/entorno_v17
```

### Opciones del instalador

| Flag | Descripción | Default |
|------|-------------|---------|
| `--enable-5g-nr` | Instalar 5G-LENA NR v5.1 NSA (opcional) | `false` |
| `--disable-lorawan` | Desactivar LoRaWAN 0.3.7 | `true` (activado) |
| `--disable-ml` | Desactivar stack Python ML | `true` (activado) |
| `--disable-sumo` | Desactivar SUMO 1.25 | `true` (activado) |
| `--workdir DIR` | Directorio de trabajo | `~/entorno_v17` |

### Ejemplo mínimo (solo NS-3 3.48 + LoRaWAN)

```bash
./install_ns3_ubuntu26_v6.sh --disable-ml --disable-sumo --disable-5g-nr
```

### Ejemplo completo (V17 completo)

```bash
./install_ns3_ubuntu26_v6.sh --enable-5g-nr --workdir ~/entorno_v17
```

Tras finalizar:

```bash
source ~/.bashrc
cd ~/entorno_v17          # directorio de trabajo creado por el instalador
ns3 show config
ns3 run first
```

### Directorio de trabajo

El instalador crea el entorno de trabajo (`venv/`, `workspace/`, `docs/`, `README.md`, `.gitignore`) en:

| Situación | Directorio de trabajo |
| --------- | --------------------- |
| Se ejecuta desde el clon del repositorio (caso de la instalación rápida) | `~/entorno_v17` (para no sobrescribir los archivos del repo) |
| Se ejecuta desde cualquier otro directorio | El directorio actual |
| Se define `NS3_WORKDIR` | La ruta indicada, p. ej. `NS3_WORKDIR=~/tesis ./install_ns3_ubuntu26_v6.sh` |

NS-3 siempre se instala en `~/ns-3.48/` y se agrega al `PATH` mediante `~/.bashrc`.

## Qué instala el script (V17)

### Simulación

| Componente | Detalle |
| ---------- | ------- |
| **NS-3** | 3.48 LTS, tarball oficial desde nsnam.org (`ns-3.48.tar.bz2`) |
| **Ubicación** | `~/ns-3.48/` |
| **Perfil de compilación** | `optimized`, con ejemplos y tests |
| **Módulos NS-3** | core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point, **lorawan, lr-wpan, sixlowpan, mesh, buildings, propagation, nr (opcional)** |
| **LoRaWAN** | **0.3.7** (módulo contribuido `ns-3-dev/ns-3-lorawan` v0.3.7, clonado y copiado a `src/lorawan/`, `helper/lorawan/`) |
| **5G-LENA NR** | **v5.1 NSA** (opcional, `--enable-5g-nr`, branch `v5.1.y` de 5G-LENA NR, requiere EPC) |
| **SUMO** | **1.25.0** (`apt install sumo sumo-tools sumo-doc`) |
| **OSM/osmium** | **osmium-tool** (`apt install osmium-tool`) |

`--enable-modules` también compila automáticamente las dependencias de esos módulos (p. ej. `propagation`, `spectrum`, `stats`, `antenna`, `lte`, `wimax`, `wpan`).

### Análisis de red

Wireshark, tshark, tcpdump, nmap, iperf3, traceroute, mtr, **osmium-tool**. Opcionales (no detienen la instalación si fallan): netstat-nat y el stack GStreamer.

### Desarrollo

- Python 3 con entorno virtual (`venv/`)
- **Librerías ML (versiones pinneadas en `requirements.lock`)**:
  - Core: numpy, pandas, scipy, scikit-learn, statsmodels
  - ML: xgboost, PyTorch, Lightning, TabPFN (opcional)
  - ASlib/COSELECT: algorithm selection framework
  - Visualización: matplotlib, seaborn, plotly
  - Utils: pyyaml, tqdm, joblib, psutil, tqdm
- `requirements.lock` con versiones exactas, `requirements.lock.txt` generado con `pip freeze`
- Git (configuración interactiva solo si no existe configuración global)
- vim, nano, htop, tree, jq, doxygen, graphviz, ccache

## Estructura tras la instalación

```
~/entorno_v17/                 # o el directorio de trabajo elegido
├── workspace/                 # Proyectos y simulaciones
├── docs/                      # Documentación generada
├── backup/                    # Respaldos y log de la prueba ns3_first_test.log
├── venv/                      # Entorno virtual Python
├── requirements.lock          # Versiones exactas de paquetes Python (pinneadas)
├── requirements.lock.txt      # Generado con pip freeze
├── README.md
├── .gitignore
├── scripts/                   # Scripts de campaña, análisis, ML
├── ml/                        # Modelos, datasets, benchmarks ESP32
├── sumo/                      # Mapas OSM, redes SUMO, trazas FCD
├── mobility/                  # Trazas de movilidad convertidas
├── scratch/                   # Simulador V17 (sim-iot-smartcity_v17.cc)
├── sumo/                      # Mapas OSM, redes SUMO, trazas FCD
├── mobility/                  # Trazas de movilidad convertidas
├── storyboard-v17/            # Storyboard V17
├── tests/                     # Tests unitarios
└── reproducibility/           # Dockerfile, reproduce.sh, SHA256SUMS.txt

~/ns-3.48/                     # NS-3 3.48 LTS
```

## Uso básico

```bash
# Entorno Python
cd ~/entorno_v17 && source venv/bin/activate

# NS-3
ns3 show config        # módulos habilitados y opciones
ns3 show profile       # perfil de compilación
ns3 show targets       # programas disponibles
ns3 run first          # ejemplo base

# SUMO
sumo --version
sumo -c la-plata.sumocfg

# Captura y análisis
sudo tcpdump -i any -w captura.pcap
tshark -r captura.pcap
iperf3 -s              # servidor
iperf3 -c <ip>         # cliente
```

> `ns3 --version` no es una opción válida de `ns3`. `ns3 show version` solo muestra la versión si NS-3 se configuró con `--enable-build-version`; en otro caso indica que está deshabilitado. Usa `ns3 show config` o `ns3 show version` (si disponible).

## Reproducibilidad

Para documentar el entorno en un trabajo académico conviene registrar:

- Versión de NS-3 (`~/ns-3.48`) y salida de `ns3 show config`
- `requirements.lock` (versiones pinneadas) y `requirements.lock.txt` (generado automáticamente)
- Versión de Ubuntu (`lsb_release -a`), compilador (`g++ --version`) y CMake (`cmake --version`)
- SHA-256 del paquete académico (`SHA256SUMS.txt`)

Para recrear el mismo entorno Python en otra máquina:

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.lock
```

## Migración desde v5 (NS-3 3.49)

1. Respaldar el trabajo de `workspace/`.
2. Ejecutar `install_ns3_ubuntu26_v6.sh`. El instalador reemplaza en `~/.bashrc` las líneas `export PATH=...ns-3.X` de instaladores anteriores (incluida `ns-3.49`) por la de 3.48, sin tocar otras líneas.
3. Recompilar los propios programas de `scratch/` o `contrib/` sobre `~/ns-3.48`; revisar las [notas de versión de ns-3.48](https://www.nsnam.org/releases/ns-3.48/release-notes.pdf) por cambios de API.
4. Opcional, una vez verificado: `rm -rf ~/ns-3.49`.

## 5G-LENA

La v6 **incluye 5G-LENA NR v5.1 como opcional** (`--enable-5g-nr`). Si se necesita:

- Se clona `https://gitlab.com/cttc-lena/nr.git` branch `v5.1.y` (compatible con ns-3.48).
- Requiere EPC compilado (incluido en la compilación de ns-3 con `nr` habilitado).
- La compatibilidad de 5G-LENA con ns-3.48 debe verificarse en el [README del módulo nr](https://gitlab.com/cttc-lena/nr) antes de instalarlo.

## Archivos del repositorio

| Archivo | NS-3 | Estado |
| ------- | ---- | ------ |
| `install_ns3_ubuntu26_v6.sh` | 3.48 LTS | **Actual (recomendado para V17)** |
| `install_ns3_ubuntu26_v5.sh` | 3.49 | Reemplazado por v6 (no recomendado para V17) |
| `install_ns3_ubuntu26_v4.sh` | 3.48 | Reemplazado por v5/v6 |
| `install_ns3_ubuntu26_v3.48_BETA.sh` | 3.48 | BETA con 5G-LENA opcional |
| `install_ns3_enhanced_V3.sh` | 3.47 (ns-allinone) | Histórico |
| `install_ns3_enhanced_V2.sh` | 3.45 | Histórico |
| `CHANGELOG.md` | — | Historial de cambios |
| `.gitignore` | — | Plantilla para proyectos del grupo |

## Notas para el grupo de investigación

- Crear simulaciones y scripts en `workspace/`; usar Git por proyecto.
- Wireshark sin root: el instalador habilita la captura para el grupo `wireshark` y agrega al usuario; hay que **cerrar sesión y volver a entrar**.
- Librerías Python adicionales: `source venv/bin/activate && pip install <paquete>` (y regenerar `pip freeze > requirements.lock.txt`).
- El instalador modifica `~/.bashrc` y `/etc/security/limits.conf` (límite de archivos abiertos 65536); antes guarda un respaldo de `.bashrc` y `.gitconfig` en `~/.config_backup_<fecha>/`.
- Para simulaciones largas, usar `screen` o `tmux`.
- **Storyboard V17**: disponible en `V17/storyboard-v17/index.html` (espejo enfocado en V17) y sección V17 en `V16/storyboard-v16/index.html`.
- **Paquete académico V17**: `entregas/V17-Entrega-Academica-20261117.zip` (291 KB, SHA-256 verificado).

## Soporte y cambios

- Cambios entre versiones: [CHANGELOG.md](./CHANGELOG.md)
- Releases NS-3: [nsnam.org](https://www.nsnam.org/releases/)
- 5G-LENA: [gitlab.com/cttc-lena/nr](https://gitlab.com/cttc-lena/nr)
- LoRaWAN: [github.com/ns-3-dev/ns-3-lorawan](https://github.com/ns-3-dev/ns-3-lorawan)
- SUMO: [sumo.dlr.de](https://sumo.dlr.de/docs/)
- OSM/osmium: [osmcode.org/osmium-tool](https://osmcode.org/osmium-tool/)

## Licencia

Uso académico e investigación. Consultar las licencias de NS-3 (GPLv2), 5G-LENA (LGPL), LoRaWAN (GPLv2), SUMO (GPLv2), y las herramientas de terceros instaladas.