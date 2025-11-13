#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR

# Creador de VM Windows (11/2022/2025) en Proxmox PVE 9.x, totalmente interactivo
# - BIOS: OVMF (UEFI), Machine: q35
# - SCSI Controller: virtio-scsi-pci
# - Qemu Agent: ON
# - TPM 2.0 y EFI Disk en storages a elegir
# - ISO existente o descarga por URL (incluye links de MS para Server 2022/2025)

set -Eeuo pipefail

# ===== Cabecera =====
header() {
  clear
  cat <<"EOF"
██     ██ ██ ███    ██ ██████   ██████  ██     ██ ███████     ███████ ███████ ██████  ██    ██ ███████ ██████  
██     ██ ██ ████   ██ ██   ██ ██    ██ ██     ██ ██          ██      ██      ██   ██ ██    ██ ██      ██   ██ 
██  █  ██ ██ ██ ██  ██ ██   ██ ██    ██ ██  █  ██ ███████     ███████ █████   ██████  ██    ██ █████   ██████  
██ ███ ██ ██ ██  ██ ██ ██   ██ ██    ██ ██ ███ ██      ██          ██ ██      ██   ██  ██  ██  ██      ██   ██ 
 ███ ███  ██ ██   ████ ██████   ██████   ███ ███  ███████     ███████ ███████ ██   ██   ████   ███████ ██   ██ 
EOF
  echo
}
header

# ===== Comprobaciones =====
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root."; exit 1; }
command -v qm >/dev/null || { echo "No se encuentra 'qm' (Proxmox)."; exit 1; }
command -v wget >/dev/null || { echo "No se encuentra 'wget'."; exit 1; }
command -v file >/dev/null || { echo "No se encuentra 'file'. Instala: apt-get update && apt-get install -y file"; exit 1; }

ISO_DIR="/var/lib/vz/template/iso"
mkdir -p "$ISO_DIR"

# ===== Utilidades =====
pause(){ read -rp "Pulsa ENTER para continuar..."; }

choose_from_list() {
  local prompt="$1"; shift
  local -a items=( "$@" )
  local choice=
  echo "$prompt"
  select choice in "${items[@]}"; do
    if [[ -n "${choice:-}" ]]; then
      echo "$choice"
      return 0
    fi
    echo "Opción inválida."
  done
}

ask_default() {
  local prompt="$1" default="$2" var
  read -rp "$prompt [$default]: " var
  echo "${var:-$default}"
}

# Devuelve storages cuyo bloque en /etc/pve/storage.cfg contiene el tipo de contenido pedido
storages_with_content() {
  local want="$1"
  [[ -f /etc/pve/storage.cfg ]] || return 0
  awk -v RS="" -v FS="\n" -v want="$want" '
    {
      name=""; content=""
      for(i=1;i<=NF;i++){
        if($i ~ /^[a-zA-Z0-9_]+: +.*/){
          name=$i; sub(/^[^:]+: +/, "", name)
        }
        if($i ~ /^[[:space:]]*content[[:space:]]+/){
          content=$i; sub(/^[[:space:]]*content[[:space:]]+/, "", content)
        }
      }
      if(name != "" && index(content, want)) print name
    }
  ' /etc/pve/storage.cfg | sort -u
}

detect_bridges() {
  local -a br=()
  # 1) /etc/network/interfaces
  if [[ -f /etc/network/interfaces ]]; then
    mapfile -t br < <(grep -oE '^\s*auto\s+(vmbr[0-9A-Za-z_-]+)' /etc/network/interfaces | awk '{print $2}' | sort -u)
  fi
  # 2) /sys/class/net
  if [[ ${#br[@]} -eq 0 ]]; then
    mapfile -t br < <(ls -1 /sys/class/net 2>/dev/null | grep -E '^vmbr|^br' || true)
  fi
  if [[ ${#br[@]} -eq 0 ]]; then
    br=( "vmbr0" )
  fi
  printf "%s\n" "${br[@]}"
}

next_vmid() {
  if command -v pvesh >/dev/null 2>&1; then
    pvesh get /cluster/nextid
  else
    # Fallback
    local last=100
    for d in /var/lib/vz/images/*; do
      [[ -d "$d" ]] || continue
      base="${d##*/}"
      [[ "$base" =~ ^[0-9]+$ ]] && (( base > last )) && last="$base"
    done
    echo $((last+1))
  fi
}

verify_iso_mount() {
  local iso="$1"
  local mnt; mnt="$(mktemp -d)"
  trap 'umount -f "$mnt" >/dev/null 2>&1 || true; rmdir "$mnt" >/dev/null 2>&1 || true' RETURN
  if mount -o loop,ro -t udf,iso9660 "$iso" "$mnt" 2>/dev/null; then
    umount "$mnt"
    return 0
  fi
  echo "No se pudo montar el ISO (¿HTML en lugar de ISO?)."
  file "$iso" || true
  return 1
}

# ===== 1) Elegir versión de Windows =====
echo "Versión de Windows:"
WIN_VER="$(choose_from_list "Elige:" "Windows 11" "Windows Server 2022" "Windows Server 2025")"
case "$WIN_VER" in
  "Windows 11")          OSTYPE_ARG="win11"; DEF_ISO_FILE="Windows11.iso"; ISO_MS="" ;;
  "Windows Server 2022") OSTYPE_ARG="win11"; DEF_ISO_FILE="windows-server-2022.iso"; ISO_MS="https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x40a&culture=es-es&country=ES" ;;
  "Windows Server 2025") OSTYPE_ARG="win11"; DEF_ISO_FILE="windows-server-2025.iso"; ISO_MS="https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x40a&culture=es-es&country=ES" ;;
esac

# ===== 2) Elegir cómo obtener la ISO =====
# Busca ISOs locales
mapfile -t LOCAL_ISOS < <(find "$ISO_DIR" -maxdepth 1 -type f -iname "*.iso" -printf "%f\n" | sort -u)
ISO_MODE=""
if [[ ${#LOCAL_ISOS[@]} -gt 0 && -n "$ISO_MS" ]]; then
  ISO_MODE="$(choose_from_list "ISO: Elige una opción" "Usar ISO local" "Descargar desde Microsoft" "Pegar URL personalizada")"
elif [[ ${#LOCAL_ISOS[@]} -gt 0 ]]; then
  ISO_MODE="$(choose_from_list "ISO: Elige una opción" "Usar ISO local" "Pegar URL personalizada")"
else
  if [[ -n "$ISO_MS" ]]; then
    ISO_MODE="$(choose_from_list "No hay ISOs locales. Elige:" "Descargar desde Microsoft" "Pegar URL personalizada")"
  else
    ISO_MODE="$(choose_from_list "No hay ISOs locales. Elige:" "Pegar URL personalizada")"
  fi
fi

ISO_FILE=""
case "$ISO_MODE" in
  "Usar ISO local")
    ISO_FILE="$(choose_from_list "Elige ISO local en $ISO_DIR:" "${LOCAL_ISOS[@]}")"
    ;;
  "Descargar desde Microsoft")
    ISO_FILE="$DEF_ISO_FILE"
    echo "Descargando ISO oficial de Microsoft para $WIN_VER ..."
    wget -L -O "$ISO_DIR/$ISO_FILE" "$ISO_MS"
    ;;
  "Pegar URL personalizada")
    read -rp "Pega la URL de la ISO: " CUSTOM_URL
    ISO_FILE="$(ask_default "Nombre destino del archivo" "$DEF_ISO_FILE")"
    echo "Descargando $CUSTOM_URL ..."
    wget -L -O "$ISO_DIR/$ISO_FILE" "$CUSTOM_URL"
    ;;
  *)
    # Solo había opción de URL personalizada
    read -rp "Pega la URL de la ISO: " CUSTOM_URL
    ISO_FILE="$(ask_default "Nombre destino del archivo" "$DEF_ISO_FILE")"
    echo "Descargando $CUSTOM_URL ..."
    wget -L -O "$ISO_DIR/$ISO_FILE" "$CUSTOM_URL"
    ;;
esac

[[ -s "$ISO_DIR/$ISO_FILE" ]] || { echo "ISO no encontrada o vacía: $ISO_DIR/$ISO_FILE"; exit 1; }
verify_iso_mount "$ISO_DIR/$ISO_FILE" || { echo "El archivo no parece ser un ISO válido. Abortando."; exit 1; }

# ===== 3) Elegir storages =====
echo
echo "Detectando storages..."
mapfile -t IMG_STOR < <(storages_with_content "images")
mapfile -t ISO_STOR < <(storages_with_content "iso")

# Storage para DISCO (images)
if [[ ${#IMG_STOR[@]} -eq 0 ]]; then
  echo "No se detectaron storages con 'images' en /etc/pve/storage.cfg"
  echo "Puedes crear uno (local-lvm, etc.) y volver a ejecutar."
  exit 1
fi
DISK_STORAGE="$(choose_from_list "Elige storage para el DISCO (images):" "${IMG_STOR[@]}")"

# Storage para EFI (images)
EFI_STORAGE="$(choose_from_list "Elige storage para el EFI Disk (images):" "${IMG_STOR[@]}")"

# Storage para TPM (images)
TPM_STORAGE="$(choose_from_list "Elige storage para el TPM State (images):" "${IMG_STOR[@]}")"

# Storage para ISO (iso)
if [[ ${#ISO_STOR[@]} -gt 0 ]]; then
  ISO_STORAGE="$(choose_from_list "Elige storage para la ISO (iso):" "${ISO_STOR[@]}")"
else
  echo "No hay storages con 'iso' declarados. Se usará 'local' (ruta $ISO_DIR) si existe."
  ISO_STORAGE="local"
fi

# ===== 4) Red: bridge y modelo =====
mapfile -t BRIDGES < <(detect_bridges)
BRIDGE="$(choose_from_list "Elige bridge de red:" "${BRIDGES[@]}")"
NETMODEL="$(choose_from_list "Modelo de NIC:" "virtio" "e1000" "rtl8139")"

# ===== 5) Parámetros de VM =====
VM_NAME="$(ask_default 'Nombre de la VM' 'Win-Guest')"
VMID="$(ask_default 'VMID (vacío para automático)' "$(next_vmid)")"
MEMORY="$(ask_default 'Memoria RAM (MiB)' '4096')"
CORES="$(ask_default 'Cores' '2')"
SOCKETS="$(ask_default 'Sockets' '1')"
DISK_SIZE="$(ask_default 'Tamaño de DISCO (ej: 60G)' '60G')"

# ===== 6) Crear VM =====
echo
echo "Creando VM $VMID ($VM_NAME)..."
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --cores "$CORES" --sockets "$SOCKETS" \
  --cpu host \
  --ostype "$OSTYPE_ARG" \
  --net0 "$NETMODEL,bridge=$BRIDGE" \
  --machine q35 \
  --bios ovmf \
  --scsihw virtio-scsi-pci \
  --agent 1

# Disco SCSI
qm set "$VMID" --scsi0 "$DISK_STORAGE:$DISK_SIZE"

# EFI Disk (con claves preinstaladas para Secure Boot)
qm set "$VMID" --efidisk0 "$EFI_STORAGE:0,efitype=4m,pre-enrolled-keys=1"

# TPM 2.0
qm set "$VMID" --tpmstate0 "$TPM_STORAGE:0,version=v2.0"

# CD-ROM (ISO elegida)
qm set "$VMID" --cdrom "$ISO_STORAGE:iso/$ISO_FILE"

# Arranque: CD primero, luego disco
qm set "$VMID" --boot order=ide2;scsi0

# ===== 7) (Opcional) Adjuntar virtio-win drivers =====
echo
read -rp "¿Adjuntar también ISO de drivers virtio-win (recomendado para Windows Server/11)? [s/N]: " ADD_VIRTIO
if [[ "${ADD_VIRTIO,,}" == "s" || "${ADD_VIRTIO,,}" == "si" ]]; then
  # Busca virtio-win en carpeta ISO
  mapfile -t VIRTIO_CAND < <(find "$ISO_DIR" -maxdepth 1 -type f -iname "virtio-win*.iso" -printf "%f\n" | sort -u)
  if [[ ${#VIRTIO_CAND[@]} -gt 0 ]]; then
    VIRTIO_ISO="$(choose_from_list "Elige ISO de virtio-win:" "${VIRTIO_CAND[@]}")"
    # Lo conectamos como segundo CD (ide3)
    qm set "$VMID" --ide3 "$ISO_STORAGE:iso/$VIRTIO_ISO,media=cdrom"
  else
    echo "No se encontró virtio-win*.iso en $ISO_DIR. Puedes descargarlo desde Fedora (virtio-win)."
  fi
fi

# ===== 8) Arranque =====
echo
echo "Iniciando VM..."
qm start "$VMID"

echo
echo "✔ VM creada e iniciada."
echo "Resumen:"
echo "  VMID:        $VMID"
echo "  Nombre:      $VM_NAME"
echo "  Windows:     $WIN_VER  (ostype=$OSTYPE_ARG)"
echo "  BIOS:        OVMF (UEFI)  | Machine: q35"
echo "  Controlador: VirtIO SCSI  | Disco: scsi0 = $DISK_STORAGE:$DISK_SIZE"
echo "  EFI Disk:    $EFI_STORAGE (pre-enrolled-keys=1)"
echo "  TPM:         $TPM_STORAGE (v2.0)"
echo "  ISO:         $ISO_STORAGE:iso/$ISO_FILE"
echo "  Red:         $NETMODEL on $BRIDGE"
echo
echo "Comprueba config con:  qm config $VMID"

