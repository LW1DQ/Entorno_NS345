# Entorno de Investigación en Redes — NS-3

Instalador automatizado para Ubuntu que configura un entorno completo de investigación en redes: **NS-3 3.49**, herramientas de análisis de tráfico y un stack Python científico en entorno virtual.

> **Versión actual:** v5.0.0 — `install_ns3_ubuntu26_v5.sh` (NS-3 3.49).
> Ver [CHANGELOG.md](./CHANGELOG.md) para el detalle de cambios respecto de versiones anteriores.
> Adaptado y orientado a **Ubuntu 26.x Desktop**; en otras versiones de Ubuntu continúa con advertencia.

## Requisitos

- **Ubuntu** (idealmente 26.x)
- **≥ 8 GB** libres en la partición de `$HOME` (allí se instala NS-3)
- **sudo** disponible
- Conexión a Internet (descarga de `ns-3.49.tar.bz2` desde nsnam.org y paquetes APT/pip)

## Instalación rápida

```bash
git clone https://github.com/LW1DQ/Entorno_NS345.git
cd Entorno_NS345
chmod +x install_ns3_ubuntu26_v5.sh
./install_ns3_ubuntu26_v5.sh
```

Tras finalizar:

```bash
source ~/.bashrc
cd ~/entorno_ns3          # directorio de trabajo creado por el instalador
ns3 show config
ns3 run first
```

### Directorio de trabajo

El instalador crea el entorno de trabajo (`venv/`, `workspace/`, `docs/`, `README.md`, `.gitignore`) en:

| Situación | Directorio de trabajo |
| --------- | --------------------- |
| Se ejecuta desde el clon del repositorio (caso de la instalación rápida) | `~/entorno_ns3` (para no sobrescribir los archivos del repo) |
| Se ejecuta desde cualquier otro directorio | El directorio actual |
| Se define `NS3_WORKDIR` | La ruta indicada, p. ej. `NS3_WORKDIR=~/tesis ./install_ns3_ubuntu26_v5.sh` |

NS-3 siempre se instala en `~/ns-3.49/` y se agrega al `PATH` mediante `~/.bashrc`.

## Qué instala el script

### Simulación

| Componente | Detalle |
| ---------- | ------- |
| **NS-3** | 3.49, tarball oficial desde nsnam.org |
| **Ubicación** | `~/ns-3.49/` |
| **Perfil de compilación** | `optimized`, con ejemplos y tests |
| **Módulos** | core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point |
| **5G-LENA** | No incluido en v5 (ver [5G-LENA](#5g-lena)) |

`--enable-modules` también compila automáticamente las dependencias de esos módulos (p. ej. `propagation`, `spectrum`, `stats`).

### Análisis de red

Wireshark, tshark, tcpdump, nmap, iperf3, traceroute, mtr. Opcionales (no detienen la instalación si fallan): netstat-nat y el stack GStreamer.

### Desarrollo

- Python 3 con entorno virtual (`venv/`)
- Librerías: pandas, numpy, matplotlib, seaborn, psutil, scipy, scikit-learn, jupyter, notebook, plotly, networkx, pyshark, scapy
- `requirements.lock.txt` con las versiones exactas instaladas (`pip freeze`)
- Git (configuración interactiva solo si no existe configuración global)
- vim, nano, htop, tree, jq

## Estructura tras la instalación

```
~/entorno_ns3/                 # o el directorio de trabajo elegido
├── workspace/                 # Proyectos y simulaciones
├── docs/TOOLS_GUIDE.md        # Guía de herramientas
├── backup/                    # Respaldos y log de la prueba ns3_first_test.log
├── venv/                      # Entorno virtual Python
├── requirements.lock.txt      # Versiones exactas de paquetes Python
├── README.md
└── .gitignore

~/ns-3.49/                     # NS-3
```

## Uso básico

```bash
# Entorno Python
cd ~/entorno_ns3 && source venv/bin/activate

# NS-3
ns3 show config        # módulos habilitados y opciones
ns3 show profile       # perfil de compilación
ns3 show targets       # programas disponibles
ns3 run first          # ejemplo base

# Captura y análisis
sudo tcpdump -i any -w captura.pcap
tshark -r captura.pcap
iperf3 -s              # servidor
iperf3 -c <ip>         # cliente
```

> `ns3 --version` no es una opción válida de `ns3`. `ns3 show version` solo muestra la versión si NS-3 se configuró con `--enable-build-version`; en otro caso indica que está deshabilitado.

## Reproducibilidad

Para documentar el entorno en un trabajo académico conviene registrar:

- Versión de NS-3 (`~/ns-3.49`) y salida de `ns3 show config`
- `requirements.lock.txt` (generado automáticamente)
- Versión de Ubuntu (`lsb_release -a`), compilador (`g++ --version`) y CMake (`cmake --version`)

Para recrear el mismo entorno Python en otra máquina:

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.lock.txt
```

## Migración desde v4 (NS-3 3.48)

1. Respaldar el trabajo de `workspace/`.
2. Ejecutar `install_ns3_ubuntu26_v5.sh`. El instalador reemplaza en `~/.bashrc` las líneas `export PATH=...ns-3.X` de instaladores anteriores (incluida `ns-allinone-3.47`) por la de 3.49, sin tocar otras líneas.
3. Recompilar los propios programas de `scratch/` o `contrib/` sobre `~/ns-3.49`; revisar las [notas de versión de ns-3](https://www.nsnam.org/releases/) por cambios de API.
4. Opcional, una vez verificado: `rm -rf ~/ns-3.48`.

## 5G-LENA

La v5 **no instala 5G-LENA**. Si se necesita el módulo `nr`:

- Usar `install_ns3_ubuntu26_v3.48_BETA.sh` con `INSTALL_5GLENA=true` (NS-3 3.48), **cambiando antes** la rama `5g-lena-v4.1.y` por `5g-lena-v5.1.y`: 5G-LENA v4.1 corresponde a ns-3.45, mientras que v5.0 y v5.1 son las compatibles con ns-3.48.
- La compatibilidad de 5G-LENA con ns-3.49 debe verificarse en el [README del módulo nr](https://gitlab.com/cttc-lena/nr) antes de instalarlo sobre 3.49.

## Archivos del repositorio

| Archivo | NS-3 | Estado |
| ------- | ---- | ------ |
| `install_ns3_ubuntu26_v5.sh` | 3.49 | **Actual (recomendado)** |
| `install_ns3_ubuntu26_v4.sh` | 3.48 | Reemplazado por v5. Conserva defectos conocidos (ver CHANGELOG) |
| `install_ns3_ubuntu26_v3.48_BETA.sh` | 3.48 | BETA con 5G-LENA opcional; única opción con 5G-LENA |
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

## Soporte y cambios

- Cambios entre versiones: [CHANGELOG.md](./CHANGELOG.md)
- Releases NS-3: [nsnam.org](https://www.nsnam.org/releases/)
- 5G-LENA: [gitlab.com/cttc-lena/nr](https://gitlab.com/cttc-lena/nr)

## Licencia

Uso académico e investigación. Consultar las licencias de NS-3 (GPLv2), 5G-LENA y las herramientas de terceros instaladas.
