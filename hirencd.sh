#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR
function header_info {
  clear
  cat <<"EOF"
██   ██ ██ ██████  ███████ ███    ██     ███████ ██████   ██████   ██████  ████████      ██████ ██████  
██   ██ ██ ██   ██ ██      ████   ██     ██      ██   ██ ██    ██ ██    ██    ██        ██      ██   ██ 
███████ ██ ██████  █████   ██ ██  ██     ███████ ██████  ██    ██ ██    ██    ██        ██      ██   ██ 
██   ██ ██ ██   ██ ██      ██  ██ ██          ██ ██   ██ ██    ██ ██    ██    ██        ██      ██   ██ 
██   ██ ██ ██   ██ ███████ ██   ████     ███████ ██████   ██████   ██████     ██         ██████ ██████   
                                                                                                                                       
EOF
}
header_info
echo -e "\n Cargando..."

# Clear the contents of the ISO directory
echo "Clearing contents of /var/lib/vz/template/iso/..."
rm -rf /var/lib/vz/template/iso/*

# Verificar si se ha pasado el ID de la VM como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <vmid>"
  exit 1
fi

VMID=$1
ISO_URL="https://www.hirensbootcd.org/files/HBCD_PE_x64.iso"
ISO_PATH="/var/lib/vz/template/iso/HBCD_PE_x64.iso"

# Descargar Hiren's BootCD si no existe
if [ ! -f "$ISO_PATH" ]; then
  echo "Descargando Hiren's BootCD..."
  wget -O "$ISO_PATH" "$ISO_URL"
  if [ $? -ne 0 ]; then
    echo "Error al descargar Hiren's BootCD."
    exit 1
  fi
fi

# Verificar si la VM existe
qm list | grep -w "$VMID" > /dev/null
if [ $? -ne 0 ]; then
  echo "La VM con ID $VMID no existe."
  exit 1
fi

# Añadir el disco de CD a la VM
echo "Añadiendo Hiren's BootCD a la VM $VMID..."
qm set $VMID --ide2 local:iso/HBCD_PE_x64.iso,media=cdrom

# Configurar la VM para que arranque desde el CD
echo "Configurando la VM $VMID para arrancar desde el CD..."
qm set $VMID --boot order=ide2

echo "Operación completada exitosamente."
