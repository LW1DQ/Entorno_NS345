# Entorno de Investigación en Redes — NS-3

Instalador automatizado para Ubuntu que configura un entorno completo de investigación en redes: **NS-3 3.47** (ns-allinone), **5G-LENA**, herramientas de análisis de tráfico y un stack Python científico.

> **Versión actual:** v3.0.0 — ver [CHANGELOG.md](CHANGELOG.md) para diferencias respecto a v2.

## Requisitos

- **Ubuntu** (el script valida el sistema operativo)
- **≥ 8 GB** de espacio libre en disco
- **sudo** disponible
- Conexión a Internet (descarga de NS-3 y clonado de 5G-LENA)

## Instalación rápida

```bash
git clone https://github.com/LW1DQ/Entorno_NS345.git
cd Entorno_NS345
chmod +x install_ns3_enhanced_V3.sh
./install_ns3_enhanced_V3.sh
```

Tras finalizar:

```bash
source ~/.bashrc
ns3 --version
ns3 run cttc-nr-demo
```

## Qué instala el script

### Simulación

| Componente | Detalle |
|------------|---------|
| **NS-3** | 3.47 desde `ns-allinone-3.47` |
| **Ubicación** | `~/ns-allinone-3.47/ns-3.47/` |
| **5G-LENA** | Módulo `nr` (ramas `5g-lena-v4.2.y` o `5g-lena-v4.1.y`) |
| **Módulos** | core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point, wave, **nr** |

### Análisis de red

Wireshark, tshark, tcpdump, nmap, iperf3, mtr, traceroute

### Desarrollo

- Python 3 con entorno virtual (`venv/`)
- Git (configuración interactiva en la primera ejecución)
- Librerías: pandas, numpy, matplotlib, seaborn, scipy, scikit-learn, jupyter, plotly, networkx, pyshark, scapy

## Estructura tras la instalación

El script crea en el directorio de ejecución:

```
├── workspace/           # Proyectos y simulaciones
├── docs/                # Guías (p. ej. TOOLS_GUIDE.md)
├── backup/              # Respaldos
├── venv/                # Entorno virtual Python
├── README.md            # Documentación local
└── .gitignore
```

NS-3 queda instalado en el home del usuario:

```
~/ns-allinone-3.47/
└── ns-3.47/             # Árbol NS-3 + contrib/nr (5G-LENA)
```

## Uso básico

### Entorno Python

```bash
source venv/bin/activate
```

### NS-3 y 5G-LENA

```bash
ns3 --version
ns3 show config | grep nr
ns3 run cttc-nr-demo
```

### Herramientas de red

```bash
# Captura
sudo tcpdump -i any -w capture.pcap

# Análisis
wireshark capture.pcap

# Rendimiento
iperf3 -s
iperf3 -c <ip_servidor>
```

## Migración desde v2

Si tenías instalada la versión anterior (NS-3 3.45 en `~/ns-3.45/`):

1. Respalda tu trabajo en `workspace/`.
2. Opcional: `rm -rf ~/ns-3.45`
3. Ejecuta `install_ns3_enhanced_V3.sh` (ver [CHANGELOG.md](CHANGELOG.md)).

## Archivos del repositorio

| Archivo | Descripción |
|---------|-------------|
| `install_ns3_enhanced_V3.sh` | Instalador actual (v3) |
| `install_ns3_enhanced_V2.sh` | Instalador anterior (NS-3 3.45) |
| `CHANGELOG.md` | Historial de cambios |
| `.gitignore` | Plantilla para proyectos del grupo |

## Notas para el grupo de investigación

- Crear simulaciones y scripts en `workspace/`.
- Usar Git por proyecto; el instalador solo configura Git global si hace falta.
- Wireshark sin root: el script añade el usuario al grupo `wireshark`; puede requerir **cerrar sesión y volver a entrar**.
- Para librerías Python extra: `source venv/bin/activate && pip install <paquete>`.

## Soporte y cambios

- Cambios entre versiones: [CHANGELOG.md](CHANGELOG.md)
- Releases NS-3: [nsnam.org](https://www.nsnam.org/releases/ns-3-47/)
- 5G-LENA: [gitlab.com/cttc-lena/nr](https://gitlab.com/cttc-lena/nr)

## Licencia

Uso académico e investigación. Consultar licencias de NS-3, 5G-LENA y herramientas de terceros incluidas.
