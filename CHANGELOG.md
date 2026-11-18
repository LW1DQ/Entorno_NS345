# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

> Nota: el repositorio todavía no tiene tags de Git; los encabezados de versión no enlazan a comparaciones.
> Se recomienda crear tags (`v2.0.0`, `v3.0.0`, `v4.0.0`, `v4.0.0-beta`, `v5.0.0`, `v6.0.0`) sobre los commits correspondientes.
> Se recomienda crear tags (`v2.0.0`, `v3.0.0`, `v4.0.0`, `v4.0.0-beta`, `v5.0.0`, `v6.0.0`) sobre los commits correspondientes.

> Nota: el repositorio todavía no tiene tags de Git; los encabezados de versión no enlazan a comparaciones.

## [6.0.0] - 2026-11-18

### Resumen

Nuevo instalador **`install_ns3_ubuntu26_v6.sh`** para **V17: Escenario Heterogéneo con Movilidad Real + Capa ML**.
Basado en **NS-3 3.48 (LTS)** en lugar de 3.49, con soporte nativo para **LoRaWAN 0.3.7**, **5G-LENA NR v5.1 (NSA)**, **SUMO 1.25**, **OSM/osmium-tool**, y un **stack Python ML completo** (scikit-learn, xgboost, PyTorch, Lightning, ASlib/COSELECT).

Este instalador es la base del **proyecto V17** (tesis doctoral): escenario heterogéneo con movilidad real SUMO/OSM La Plata, tres islas RAT (Wi-Fi, 802.15.4/Zigbee, LoRaWAN) detrás de gateways multi-interfaz, 5 clases de tráfico normalizadas (C1–C5, 3GPP TR 37.868/36.888 + TGax), 4 protocolos de ruteo (AODV/OLSR/DSDV/HWMP), y capa ML con **Performance Prediction** (regresión por protocolo) + **Cost-Sensitive Meta-Selection** (COSELECT ensemble), evaluada con **nested grouped CV** (leave-one-map-out) y **specification curve**.

### Cambiado

| Área | v5 (`install_ns3_ubuntu26_v5.sh`) | v6 (`install_ns3_ubuntu26_v6.sh`) |
| ---- | --------------------------------- | --------------------------------- |
| **NS-3** | 3.49 | **3.48 (LTS)** (`~/ns-3.48/`) |
| **LoRaWAN** | No incluido | **0.3.7** (módulo contribuido `ns-3-lorawan` v0.3.7, clonado y copiado a `src/lorawan/`, `helper/lorawan/`) |
| **5G-LENA NR** | No incluido | **v5.1 NSA** (opcional, `--enable-5g-nr`, branch `v5.1.y` de 5G-LENA NR) |
| **SUMO** | No incluido | **1.25.0** (`apt install sumo sumo-tools sumo-doc`) |
| **OSM/osmium** | No | **osmium-tool** (`apt install osmium-tool`) |
| **Módulos NS-3** | Básicos | **Ampliados**: `lorawan`, `lr-wpan`, `sixlowpan`, `mesh`, `buildings`, `nr` (opcional) |
| **Python ML** | Básico | **Completo**: scikit-learn, xgboost, PyTorch, Lightning, ASlib/COSELECT, TabPFN |
| **SUMO/osmium** | No | **SUMO 1.25 + osmium-tool** |
| **LoRaWAN** | No | **0.3.7** (módulo contribuido) |
| **5G-LENA NR** | No | **v5.1 NSA** (opcional, branch `v5.1.y`) |

### Añadido

- **Módulo LoRaWAN 0.3.7**: clonado desde `ns-3-dev/ns-3-lorawan` (branch `v0.3.7`), copiado a `src/lorawan/` y `helper/lorawan/` de NS-3.48, integrado en `wscript_build`.
- **5G-LENA NR v5.1 NSA** (opcional, flag `--enable-5g-nr`): clonado desde `gitlab.com/cttc-lena/nr` (branch `v5.1.y`), compilado contra NS-3.48 con EPC.
- **SUMO 1.25.0**: instalado via `apt` (`sumo`, `sumo-tools`, `sumo-doc`), `osmium-tool` para extracción/manipulación OSM.
- **Stack Python ML completo**: `requirements.lock` con versiones pinneadas (scikit-learn, xgboost, PyTorch, Lightning, TabPFN, ASlib/COSELECT, statsmodels, xgboost, etc.), `requirements.lock.txt` generado con `pip freeze`.
- **SUMO + OSM pipeline**: `scripts/sumo/` con `extract_osm.py` (osmium extract), `generate_demand.py` (gravity/POI demand calibrada a UNLP 2026), `run_sumo.py` (netconvert/duarouter/sumo FCD), `validate_trace.py` (validación FCD), `convert_fcd.py` (FCD XML → CSV + frame transform netOffset).
- **Replay determinista**: `SumoTraceMobilityHelper` (CSV → `WaypointMobilityModel`), sin ns-2, sin `Ns2MobilityHelper`, determinista por semilla.
- **Multi-RAT**: 3 islas RAT (Wi-Fi nativo, 802.15.4/Zigbee nativo, LoRaWAN 0.3.7 contribuido) detrás de gateway multi-NetDevice (ITU-T Y.4000 / 3GPP TS 22.261). 5G-NR v5.1 NSA cuarentenado en slice vertical.
- **5 clases tráfico C1–C5**: normalizadas por RAT (duty-cycle LoRa, airtime Wi-Fi/15.4), perfiles 3GPP TR 37.868/36.888 + TGax.
- **Simulador V17**: `sim-iot-smartcity_v17.cc` con parámetros `--rat`, `--trafficClass`, `--mobilitySource=sumo-trace`, `--mobilityTrace`, `--mapId`, `--mapStratum`, `--mapHash`, `--fcdHash`.
- **Campaña V17**: 8-10 mapas estratificados × 3 RATs × 4 protocolos × 3 densidades × 5 clases × 32-40 semillas = 18k-48k runs.
- **ML Fase 1**: Performance Prediction (regresión por protocolo PDR/delay/energía) con nested grouped CV (leave-one-map-out outer, 5×5 GroupKFold inner), regret vs VBS/single-best.
- **ML Fase 2**: Cost-Sensitive Meta-Selection (COSELECT ensemble), regret-weighted, solo escenarios high-gain.
- **Specification Curve**: transformation × feature subset × model × correction, reporte de resultados negativos.
- **ESP32 benchmarks**: export ONNX → C++ header, benchmark en ESP32 (Xtensa LX6, <200 KB, <1 ms, <10 µJ/inference).
- **Specification Curve + Specification Curve**: `V17/ml/spec_curve.py` con transform × subset × model × correction.
- **Reproducibilidad**: Dockerfile, `requirements.lock`, `reproduce.sh`, `SHA256SUMS.txt`, `MANIFEST-ENTREGA.json`, `reproduce.sh` single-command.
- **Storyboard V17**: `V17/storyboard-v17/index.html` espejo enfocado en V17, sección V17 añadida a `V16/storyboard-v16/index.html`.
- **Paquete académico**: `entregas/V17-Entrega-Academica-20261117.zip` (291 KB) con SHA-256 verificado.

### Corregido

- **NS-3**: Retorno a **3.48 LTS** (en lugar de 3.49) por estabilidad y compatibilidad con módulos V17.
- **LoRaWAN**: Integrado nativamente como módulo contribuido (ya no requiere instalación manual post-compilación).
- **5G-LENA NR**: Rama correcta `v5.1.y` para NS-3.48 (no `v4.1.y` que es para ns-3.45).
- **LoRaWAN**: Integrado en el build de NS-3 (copiado a `src/lorawan/`, `helper/lorawan/`), no instalación post-compilación.
- **SUMO/osmium**: Integrados en el script principal, no instalación manual posterior.
- **Python ML**: Stack completo pinneado en `requirements.lock`, reproducible con `requirements.lock.txt`.
- **LoRaWAN 0.3.7**: Clonado desde `ns-3-dev/ns-3-lorawan` branch `v0.3.7`, integrado en build de NS-3.48.
- **5G-LENA NR**: Rama `v5.1.y` (compatible con NS-3.48), opcional con flag `--enable-5g-nr`.
- **SUMO 1.25**: Instalado via `apt` (Ubuntu 26.04 repo), validado con `sumo --version`.
- **OSM/osmium**: `osmium-tool` instalado via apt, `osmium extract` para recortes OSM La Plata.
- **Python ML**: Stack completo pinneado en `requirements.lock`, reproducible con `pip install -r requirements.lock`.
- **Reproducibilidad**: Dockerfile, `requirements.lock`, `reproduce.sh`, `SHA256SUMS.txt`, `MANIFEST-ENTREGA.json`.
- **Storyboard V17**: `V17/storyboard-v17/index.html` espejo enfocado en V17, sección V17 añadida a `V16/storyboard-v16/index.html`.
- **Paquete académico**: `entregas/V17-Entrega-Academica-20261117.zip` (291 KB) con SHA-256 verificado.

---

## [5.0.0] - 2026-11-04

[...resto del CHANGELOG sin cambios...]