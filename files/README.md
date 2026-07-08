# Entorno de Investigación en Redes — NS-3

Instalador automatizado para Ubuntu que configura un entorno completo de investigación en redes: **NS-3 3.48**, **5G-LENA (opcional)**, herramientas de análisis de tráfico y un stack Python científico.

> **Versión actual:** v4.0.0-beta — ver [CHANGELOG.md](./CHANGELOG.md) para diferencias respecto a v3.
> Esta versión es **BETA**, adaptada y probada sobre **Ubuntu 26.x** (continúa en otras versiones con advertencia).

## Requisitos

- **Ubuntu** (idealmente 26.x; el script valida el sistema y advierte si es otra versión)
- **≥ 8 GB** de espacio libre en disco
- **sudo** disponible
- Conexión a Internet (descarga de NS-3 y, opcionalmente, clonado de 5G-LENA)

## Instalación rápida

```bash
git clone https://github.com/LW1DQ/Entorno_NS345.git
cd Entorno_NS345
chmod +x install_ns3_ubuntu26_v3_48_BETA.sh
./install_ns3_ubuntu26_v3_48_BETA.sh
```

Tras finalizar:

```bash
source ~/.bashrc
ns3 --version
ns3 show version
ns3 run first
```

### ¿Necesitás 5G-LENA?

A partir de v4, 5G-LENA **no se instala por defecto**. Editá la variable al inicio del script antes de ejecutarlo:

```bash
INSTALL_5GLENA=true
```

## Qué instala el script

### Simulación

| Componente | Detalle |
| ---------- | ------- |
| **NS-3** | 3.48, tarball directo desde nsnam.org (sin ns-allinone) |
| **Ubicación** | `~/ns-3.48/` |
| **5G-LENA** | Opcional, módulo `nr` (rama `5g-lena-v4.1.y`) — activar con `INSTALL_5GLENA=true` |
| **Módulos** | core, network, internet, mobility, wifi, mesh, energy, flow-monitor, aodv, dsdv, olsr, applications, csma, point-to-point, wave, bridge, traffic-control, **netanim** |

### Análisis de red

Wireshark, tshark, tcpdump, nmap, iperf3, traceroute, mtr, net-tools

### Desarrollo

- Python 3 con entorno virtual (`venv/`)
- Git (configuración interactiva en la primera ejecución)
- Librerías: pandas, numpy, matplotlib, seaborn, psutil, scipy, scikit-learn, jupyter, notebook, plotly, networkx, pyshark, scapy
- Herramientas de documentación/build adicionales: doxygen, graphviz, texlive, cmake, ninja-build, openmpi

## Estructura tras la instalación

El script crea en el directorio de ejecución:

```
├── workspace/    # Proyectos y simulaciones
├── scripts/      # Scripts auxiliares
├── notebooks/    # Notebooks de análisis
├── results/      # Resultados generados
├── traces/       # Trazas .pcap/.tr
├── docs/         # Documentación (README, TOOLS_GUIDE.md)
├── backup/       # Respaldos
├── venv/         # Entorno virtual Python
└── .gitignore
```

NS-3 queda instalado en el home del usuario:

```
~/ns-3.48/
└── contrib/nr/   # 5G-LENA, solo si INSTALL_5GLENA=true
```

## Uso básico

### Entorno Python

```bash
source venv/bin/activate
```

### NS-3

```bash
ns3 --version
ns3 show config
ns3 run first
```

### 5G-LENA (si se instaló)

```bash
ns3 run cttc-nr-demo
```

### Herramientas de red

```bash
# Captura
sudo tcpdump -i any -w traces/capture.pcap

# Análisis
wireshark traces/capture.pcap
tshark -r traces/capture.pcap

# Rendimiento
iperf3 -s
iperf3 -c <ip_servidor>
```

## Migración desde v3

Si tenías instalada la versión anterior (NS-3 3.47 en `~/ns-allinone-3.47/`):

1. Respalda tu trabajo en `workspace/`.
2. Opcional: `rm -rf ~/ns-allinone-3.47`
3. Si dependés de 5G-LENA, recordá poner `INSTALL_5GLENA=true` antes de ejecutar — en v3 se instalaba por defecto.
4. Ejecutá `install_ns3_ubuntu26_v3_48_BETA.sh` (ver [CHANGELOG.md](./CHANGELOG.md)).

## Archivos del repositorio

| Archivo | Descripción |
| ------- | ----------- |
| `install_ns3_ubuntu26_v3_48_BETA.sh` | Instalador actual (v4, BETA) |
| `install_ns3_enhanced_V3.sh` | Instalador anterior (NS-3 3.47, ns-allinone) |
| `install_ns3_enhanced_V2.sh` | Instalador (NS-3 3.45) |
| `CHANGELOG.md` | Historial de cambios |
| `.gitignore` | Plantilla para proyectos del grupo |

## Notas para el grupo de investigación

- Crear simulaciones y scripts en `workspace/` o `scripts/`; guardar trazas en `traces/` y resultados en `results/`.
- Usar Git por proyecto; el instalador solo configura Git global si hace falta.
- Wireshark sin root: el script añade el usuario al grupo `wireshark`; puede requerir **cerrar sesión y volver a entrar**.
- Para librerías Python extra: `source venv/bin/activate && pip install <paquete>`.
- Esta versión es BETA: si encontrás fallas en instalación de paquetes o compilación, reportalas antes de que se marque como release estable.

## Soporte y cambios

- Cambios entre versiones: [CHANGELOG.md](./CHANGELOG.md)
- Releases NS-3: [nsnam.org](https://www.nsnam.org/releases/)
- 5G-LENA: [gitlab.com/cttc-lena/nr](https://gitlab.com/cttc-lena/nr)

## Licencia

Uso académico e investigación. Consultar licencias de NS-3, 5G-LENA y herramientas de terceros incluidas.
