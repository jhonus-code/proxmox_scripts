#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR

#!/usr/bin/env bash
set -Eeuo pipefail

header_info() {
  clear
  cat <<"EOF"
██     ██ ██ ███    ██ ██████   ██████  ██     ██ ███████     ███████ ███████ ██████  ██    ██ ███████ ██████  
██     ██ ██ ████   ██ ██   ██ ██    ██ ██     ██ ██          ██      ██      ██   ██ ██    ██ ██      ██   ██ 
██  █  ██ ██ ██ ██  ██ ██   ██ ██    ██ ██  █  ██ ███████     ███████ █████   ██████  ██    ██ █████   ██████  
██ ███ ██ ██ ██  ██ ██ ██   ██ ██    ██ ██ ███ ██      ██          ██ ██      ██   ██  ██  ██  ██      ██   ██ 
 ███ ███  ██ ██   ████ ██████   ██████   ███ ███  ███████     ███████ ███████ ██   ██   ████   ███████ ██   ██ 
EOF
}
header_info
echo -e "\n Cargando..."

if [[ $EUID -ne 0 ]]; then echo "Ejecuta como root."; exit 1; fi
command -v qm >/dev/null || { echo "No se encuentra 'qm' (Proxmox)."; exit 1; }
command -v wget >/dev/null || { echo "No se encuentra 'wget'."; exit 1; }
command -v file >/dev/null || { echo "No se encuentra 'file'. apt-get install file"; exit 1; }
command -v pvesm >/dev/null || { echo "No se encuentra 'pvesm'."; exit 1; }
command -v swtpm >/dev/null || echo "Aviso: 'swtpm' no encontrado; instala 'swtpm' si falla el TPM."

VM_NAME="Server"
MEMORY="4096"
DISK_SIZE="${DISK_SIZE:-60G}"
BRIDGE="${BRIDGE:-vmbr0}"

ISO_STORAGE="local"
DISK_STORAGE="${DISK_STORAGE:-local-lvm}"
EFI_TPM_STORAGE="${EFI_TPM_STORAGE:-$DISK_STORAGE}"

if ! pvesm status | awk 'NR>1{print $1}' | grep -qx "$DISK_STORAGE"; then
  echo "Storage $DISK_STORAGE no existe; usando 'local' para discos."
  DISK_STORAGE="local"
fi
if ! pvesm status | awk 'NR>1{print $1}' | grep -qx "$EFI_TPM_STORAGE"; then
  echo "Storage $EFI_TPM_STORAGE no existe; usando '$DISK_STORAGE' para EFI/TPM."
  EFI_TPM_STORAGE="$DISK_STORAGE"
fi

echo "Selecciona Windows Server:"
PS3="Opción: "
options=("Windows Server 2016" "Windows Server 2019" "Windows Server 2022" "Windows Server 2025" "Salir")
select opt in "${options[@]}"; do
  case "$opt" in
    "Windows Server 2016")
      ISO_FILE="windows-server-2016.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x40a&culture=es-es&country=ES"
      OSType="win10"; break;;
    "Windows Server 2019")
      ISO_FILE="windows-server-2019.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x40a&culture=es-es&country=ES"
      OSType="win10"; break;;
    "Windows Server 2022")
      ISO_FILE="windows-server-2022.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x40a&culture=es-es&country=ES"
      OSType="win11"; break;;
    "Windows Server 2025")
      ISO_FILE="windows-server-2025.iso"
      ISO_URL="https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x40a&culture=es-es&country=ES"
      OSType="win11"; break;;
    "Salir") echo "Saliendo..."; exit 0;;
    *) echo "Opción inválida $REPLY";;
  esac
done

ISO_PATH="/var/lib/vz/template/iso/${ISO_FILE}"
mkdir -p /var/lib/vz/template/iso

if [[ ! -f "$ISO_PATH" ]]; then
  echo "Descargando ISO desde $ISO_URL ..."
  wget -L -O "$ISO_PATH" "$ISO_URL" || { echo "Fallo al descargar $ISO_URL"; exit 1; }
else
  echo "El ISO $ISO_FILE ya existe; se omite la descarga."
fi

if [[ ! -s "$ISO_PATH" ]]; then echo "El ISO está vacío o corrupto."; exit 1; fi
echo "Tipo MIME: $(file -b --mime-type "$ISO_PATH" || true)"

mnt="$(mktemp -d)"
trap 'umount -f "$mnt" >/dev/null 2>&1 || true; rmdir "$mnt" >/dev/null 2>&1 || true' RETURN
if mount -o loop,ro -t udf,iso9660 "$ISO_PATH" "$mnt" 2>/dev/null; then
  umount "$mnt"; echo "ISO verificado correctamente."
else
  echo "No se pudo montar el ISO. Abortando."; exit 1
fi

if command -v pvesh >/dev/null 2>&1; then
  VM_ID="$(pvesh get /cluster/nextid)"
else
  last=99
  for d in /var/lib/vz/images/*/; do
    [[ -d "$d" ]] || continue
    id=${d%/}; id=${id##*/}
    [[ "$id" =~ ^[0-9]+$ ]] && (( id>last )) && last=$id
  done
  VM_ID=$((last+1))
fi
echo "Creando VM con ID: $VM_ID"

qm create "$VM_ID" \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --ostype "$OSType" \
  --machine q35 \
  --bios ovmf \
  --scsihw virtio-scsi-pci \
  --agent 1 \
  --net0 virtio,bridge="$BRIDGE"

qm set "$VM_ID" --efidisk0 "$EFI_TPM_STORAGE:0,efitype=4m,pre-enrolled-keys=1"
qm set "$VM_ID" --tpmstate0 "$EFI_TPM_STORAGE:0,version=v2.0"
qm set "$VM_ID" --scsi0 "$DISK_STORAGE:$DISK_SIZE"
qm set "$VM_ID" --cdrom "$ISO_STORAGE:iso/${ISO_FILE}"
qm set "$VM_ID" --boot order=ide2;scsi0

echo "Iniciando VM..."
qm start "$VM_ID"

echo
echo "VM $VM_ID lista:"
echo "  BIOS OVMF, q35, VirtIO SCSI, Agent, TPM 2.0, EFI Disk en $EFI_TPM_STORAGE"
echo "  Disco $DISK_SIZE en $DISK_STORAGE (scsi0) | ISO ${ISO_FILE} en $ISO_STORAGE (ide2)"
echo "  Red virtio en $BRIDGE"
echo "Comprueba: qm config $VM_ID | egrep 'bios|machine|scsihw|agent|tpmstate0|efidisk0|scsi0|ide2|boot|net0'"



