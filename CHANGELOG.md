# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [3.0.0] - 2026-05-15

### Resumen

Actualización mayor del instalador: **NS-3 3.45 → 3.47**, distribución vía **ns-allinone**, selección automática de rama **5G-LENA** compatible, y mejoras de robustez en reinstalaciones.

### Añadido

- Variables centralizadas de versión y rutas: `NS_VERSION`, `NS_ALLINONE_DIR`, `NS3_DIR`, `NS_ALLINONE_ARCHIVE`, `NS_ALLINONE_URL`.
- Función `checkout_5g_lena_branch()` que prueba ramas en orden: `5g-lena-v4.2.y`, luego `5g-lena-v4.1.y`.
- `set -u` para fallar si se usan variables no definidas.
- Comprobación de `sudo` al inicio de `main()`.
- Entradas en `.gitignore` para artefactos de NS-3 (`*.o`, `*.a`, `build/`, `.lock-waf*`) y patrones Python ampliados.

### Cambiado

| Área | v2 | v3 |
|------|----|----|
| **NS-3** | 3.45 (`ns-3.45.tar.bz2`) | **3.47** (`ns-allinone-3.47.tar.bz2`) |
| **Instalación** | Solo tarball `ns-3.45` | Paquete **ns-allinone** oficial |
| **Ruta** | `~/ns-3.45/` | `~/ns-allinone-3.47/ns-3.47/` |
| **5G-LENA** | Rama fija `5g-lena-v4.1.y` | Selección automática v4.2.y / v4.1.y |
| **venv APT** | `python3.12-venv` | `python3-venv` (más portable entre Ubuntu) |
| **Banner** | “Instalación de herramientas…” | “ENTORNO DE INVESTIGACIÓN EN REDES — INSTALADOR V3” |
| **Script** | `install_ns3_enhanced_V2.sh` | `install_ns3_enhanced_V3.sh` |
| **README / docs** (generados) | Referencias a 3.45 y `~/ns-3.45/` | Referencias a 3.47 y `~/ns-allinone-3.47/ns-3.47/` |

### Corregido

- **PATH en `~/.bashrc`**: no duplica la línea `export PATH` si ya existe.
- **`/etc/security/limits.conf`**: no repite entradas `nofile 65536` en ejecuciones sucesivas.
- **`usermod` Wireshark**: uso correcto de `"$USER"` entre comillas.
- Rutas hardcodeadas `~/ns-3.45` sustituidas por variables (`$NS3_DIR`, `$NS_ALLINONE_DIR`).

### Sin cambios relevantes

- Flujo general: actualización del sistema → dependencias → Git → estructura → NS-3 + 5G-LENA → Python venv → documentación → permisos → verificación.
- Paquetes de análisis de red (Wireshark, tcpdump, nmap, iperf3, mtr, etc.).
- Librerías Python (pandas, numpy, matplotlib, jupyter, pyshark, scapy, etc.).
- Módulos NS-3 habilitados (incluido `nr`).

### Migración desde v2

1. Hacer backup de simulaciones en `workspace/` si las tienes.
2. Opcional: eliminar instalación anterior:
   ```bash
   rm -rf ~/ns-3.45
   ```
3. Ejecutar el nuevo instalador:
   ```bash
   chmod +x install_ns3_enhanced_V3.sh
   ./install_ns3_enhanced_V3.sh
   ```
4. Recargar entorno:
   ```bash
   source ~/.bashrc
   ns3 --version
   ns3 run cttc-nr-demo
   ```

### Requisitos

- Ubuntu (comprobado por el script).
- ≥ 8 GB libres en disco.
- Acceso a Internet para descargar `ns-allinone-3.47.tar.bz2` y clonar 5G-LENA desde GitLab.

## [2.0.0] - Versión anterior (GitHub)

- Instalador `install_ns3_enhanced_V2.sh`.
- NS-3 3.45 desde `ns-3.45.tar.bz2`.
- 5G-LENA con rama fija `5g-lena-v4.1.y`.
- Entorno de investigación en redes con herramientas de análisis y Python venv.

[3.0.0]: https://github.com/LW1DQ/Entorno_NS345/compare/v2.0.0...v3.0.0
