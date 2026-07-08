# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [4.0.0-beta](https://github.com/LW1DQ/Entorno_NS345/compare/v3.0.0...v4.0.0-beta) - 2026-07-08

### Resumen

Actualización mayor del instalador: **NS-3 3.47 (ns-allinone) → 3.48 (tarball directo)**, **5G-LENA pasa de instalación por defecto a opcional** (`INSTALL_5GLENA`), instalación de paquetes APT resiliente a fallos opcionales, chequeo explícito de Ubuntu 26.x, prueba funcional automática post-instalación (`run_test`) y resumen final estructurado. Publicado como BETA sobre Ubuntu 26.

### Añadido

- `check_ubuntu()`: valida que el SO sea Ubuntu y advierte (sin abortar) si `VERSION_ID` no es 26.x.
- `install_apt_package()`: instalación paquete-por-paquete con distinción **requerido/opcional**; un paquete opcional fallido ya no aborta el script (antes cualquier fallo detenía todo).
- Lista de paquetes opcionales dedicada al stack GStreamer completo, separada de los requeridos.
- Paquetes nuevos en la lista requerida: `ninja-build`, `python3-setuptools`, `ca-certificates`, `libgsl-dev`, `libeigen3-dev`, `openmpi-bin`, `openmpi-common`, `libopenmpi-dev`, `doxygen`, `graphviz`, `imagemagick`, `texlive`, `texlive-latex-extra`, `texlive-font-utils`, `net-tools`, `screen`, `tmux`.
- Módulo `netanim` agregado a `NS3_MODULES`.
- Verificación defensiva del grupo `wireshark` antes de `usermod` (`getent group wireshark`).
- Fallback de configuración de NS-3: si `./ns3 configure --enable-modules="$NS3_MODULES"` falla, reintenta con módulos por defecto en lugar de abortar directamente.
- Nuevos directorios de trabajo: `results/`, `traces/`, `scripts/`, `notebooks/` (antes solo `workspace/`, `docs/`, `backup/`).
- `.gitignore` ampliado: `results/`, `traces/`, `logs/`, `compile_commands.json`, `cmake-cache/`, `.lock-ns3*`.
- `run_test()`: ejecuta `ns3 run first` como prueba de humo tras la instalación (y `cttc-nr-demo` si `INSTALL_5GLENA=true`).
- `show_summary()`: resumen final con checklist de lo instalado y próximos pasos sugeridos.
- Documentación generada (`README.md`, `docs/TOOLS_GUIDE.md`) ahora incluye bloques condicionales según `INSTALL_5GLENA` en lugar de texto estático.
- Verificación de consistencia 5G-LENA: advierte si `contrib/nr` existe sin haberse solicitado, o si se solicitó y no se encuentra.
- `trap 'log_error ...; exit 1' INT TERM` para salida controlada ante interrupción manual.

### Cambiado

| Área | v3.0.0 | v4.0.0-beta |
| ---- | ------ | ----------- |
| **NS-3** | 3.47 (`ns-allinone-3.47.tar.bz2`) | **3.48** (`ns-3.48.tar.bz2`, sin allinone) |
| **Ruta de instalación** | `~/ns-allinone-3.47/ns-3.47/` | `~/ns-3.48/` |
| **5G-LENA** | Instalado por defecto, integrado en la primera compilación | **Opcional** vía `INSTALL_5GLENA` (por defecto `false`), paso separado tras compilar NS-3 base |
| **Selección de rama 5G-LENA** | `checkout_5g_lena_branch()` prueba `5g-lena-v4.2.y` → `5g-lena-v4.1.y` | Solo `5g-lena-v4.1.y` (sin fallback multi-rama) |
| **Manejo de errores global** | `set -u` | `set -o pipefail` + `trap` en `INT`/`TERM` |
| **Instalación de paquetes** | Lista plana; cualquier fallo aborta el script | `install_apt_package()` con distinción requerido/opcional; solo un requerido fallido aborta |
| **Script** | `install_ns3_enhanced_V3.sh` | `install_ns3_ubuntu26_v3_48_BETA.sh` |
| **Banner** | "ENTORNO DE INVESTIGACIÓN EN REDES — INSTALADOR V3" | "INSTALACIÓN DE HERRAMIENTAS PARA INVESTIGACIÓN EN REDES" (NS-3 3.48) |
| **README / docs generados** | Heredocs estáticos, referencias fijas a 3.47/ns-allinone | Heredocs interpolados dinámicamente según versión y `INSTALL_5GLENA` |

### Corregido / Endurecido

- `read -r -p` en prompts interactivos (Git, reinstalación de NS-3/5G-LENA) para evitar mangling de backslashes, no presente de forma consistente en v3.
- `install_python_dependencies()`: cada instalación de paquete pip fallida ahora hace `deactivate` antes de retornar error (evita dejar el venv activado en un `exit` fallido).
- Chequeo de grupo `wireshark` antes de `usermod`, evitando error si el paquete no registró el grupo.

### Pendiente de confirmar antes del release estable

- **Cambio de comportamiento por defecto**: con v3, todo el grupo de investigación recibía 5G-LENA instalado automáticamente. Con v4, `INSTALL_5GLENA=false` por defecto — quienes actualicen deben editar la variable o pasarla explícitamente si dependen del módulo `nr`.
- **Regresión de robustez en selección de rama 5G-LENA**: v3 probaba dos ramas candidatas (`v4.2.y`, `v4.1.y`); v4 solo intenta `v4.1.y`. Si la intención es simplificar, documentarlo; si es un descuido, restaurar el fallback.
- Confirmar si `install_ns3_ubuntu26_v3_48_BETA.sh` se renombra a `install_ns3_enhanced_V4.sh` al salir de beta, siguiendo la convención de nombres usada en v2/v3.

### Migración desde v3.0.0

1. Hacer backup de simulaciones en `workspace/` si las tenés.
2. Opcional: eliminar instalación anterior:

   ```bash
   rm -rf ~/ns-allinone-3.47
   ```

3. Ejecutar el nuevo instalador. Si necesitás 5G-LENA, editar `INSTALL_5GLENA=true` en el script antes de correrlo:

   ```bash
   chmod +x install_ns3_ubuntu26_v3_48_BETA.sh
   ./install_ns3_ubuntu26_v3_48_BETA.sh
   ```

4. Recargar entorno:

   ```bash
   source ~/.bashrc
   ns3 --version
   ns3 show config
   ```

### Requisitos

- Ubuntu (idealmente 26.x; otras versiones generan advertencia pero continúan).
- ≥ 8 GB libres en disco.
- Acceso a Internet para descargar `ns-3.48.tar.bz2` desde nsnam.org y, si `INSTALL_5GLENA=true`, clonar 5G-LENA desde GitLab.

## [3.0.0](https://github.com/LW1DQ/Entorno_NS345/compare/v2.0.0...v3.0.0) - 2026-05-15

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
| ---- | -- | -- |
| **NS-3** | 3.45 (`ns-3.45.tar.bz2`) | **3.47** (`ns-allinone-3.47.tar.bz2`) |
| **Instalación** | Solo tarball `ns-3.45` | Paquete **ns-allinone** oficial |
| **Ruta** | `~/ns-3.45/` | `~/ns-allinone-3.47/ns-3.47/` |
| **5G-LENA** | Rama fija `5g-lena-v4.1.y` | Selección automática v4.2.y / v4.1.y |
| **venv APT** | `python3.12-venv` | `python3-venv` (más portable entre Ubuntu) |
| **Banner** | "Instalación de herramientas…" | "ENTORNO DE INVESTIGACIÓN EN REDES — INSTALADOR V3" |
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
