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

VMID=$1
ISO_URL="https://www.hirensbootcd.org/files/HBCD_PE_x64.iso"
ISO_PATH="/var/lib/vz/template/iso/HBCD_PE_x64.iso"

# Clear the contents of the ISO directory
echo "Clearing contents of /var/lib/vz/template/iso/..."
rm -rf /var/lib/vz/template/iso/*

# Función para mostrar el menú y obtener el VMID del usuario
get_vm_id() {
  echo "Seleccione una opción:"
  echo "1. Ingresar manualmente el ID de la VM"
  echo "2. Salir"

  read -p "Opción: " option

  case $option in
    1)
      read -p "Ingrese el ID de la VM: " VMID
      ;;
    2)
      echo "Saliendo del script."
      exit 0
      ;;
    *)
      echo "Opción no válida. Por favor, seleccione una opción válida."
      get_vm_id
      ;;
  esac
}

# Verificar si se ha pasado el ID de la VM como argumento
if [ -z "$1" ]; then
  get_vm_id
else
  VMID=$1
fi

# Crear el directorio si no existe
if [ ! -d "/var/lib/vz/template/iso" ]; then
  mkdir -p /var/lib/vz/template/iso
fi

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
if [ $? -ne 0 ]; then
  echo "Error al añadir el disco de CD a la VM."
  exit 1
fi

# Configurar la VM para que arranque desde el CD
echo "Configurando la VM $VMID para arrancar desde el CD..."
qm set $VMID --boot order=ide2
if [ $? -ne 0 ]; then
  echo "Error al configurar el arranque desde el CD."
  exit 1
fi

echo "Operación completada exitosamente."
