# Entorno de Investigación en Redes - NS-3

## Descripción
Este entorno proporciona todas las herramientas necesarias para investigación en redes utilizando NS-3, herramientas de análisis y un entorno de desarrollo completo.

## Herramientas Instaladas

### Simulación
- **NS-3 3.45** - Simulador de redes discreto
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
