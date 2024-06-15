#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre
function header_info {
  clear
  cat <<"EOF"
   ____  ____  _   _______ _______   _______ ______
  / __ \/ __ \/ | / / ___// ____/ | / / ___// ____/
 / / / / /_/ /  |/ /\__ \/ __/ /  |/ /\__ \/ __/   
/ /_/ / ____/ /|  /___/ / /___/ /|  /___/ / /___   
\____/_/   /_/ |_//____/_____/_/ |_//____/_____/   
                                                   
EOF
}
header_info
echo -e "\n Cargando..."

# Variables
OPNSENSE_VERSION="24.1"
ISO_URL="https://mirror.dns-root.de/opnsense/releases/${OPNSENSE_VERSION}/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso.bz2"
ISO_COMPRESSED="/var/lib/vz/template/iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso.bz2"
ISO_UNCOMPRESSED="/var/lib/vz/template/iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso"
VM_ID="108"
VM_NAME="OPNsense"
STORAGE="local"
MEMORY="512"
DISK_SIZE="32G"
BRIDGE="vmbr0"

# Descargar la imagen ISO de OPNsense si no existe
if [ ! -f $ISO_COMPRESSED ]; then
    echo "Descargando OPNsense ISO..."
    wget $ISO_URL -O $ISO_COMPRESSED
else
    echo "El archivo comprimido ya existe. No se descargará nuevamente."
fi

# Descomprimir la imagen ISO si no está descomprimida
if [ -f $ISO_COMPRESSED ] && [ ! -f $ISO_UNCOMPRESSED ]; then
    echo "Descomprimiendo el ISO..."
    bunzip2 $ISO_COMPRESSED
else
    echo "El archivo ISO descomprimido ya existe o no se encontró el archivo comprimido."
fi

# Verificar que la ISO descomprimida existe
if [ ! -f $ISO_UNCOMPRESSED ]; then
    echo "No se pudo descargar y descomprimir el ISO de OPNsense."
    exit 1
fi

# Variables adicionales para la creación del disco
DISK_PATH="/var/lib/vz/images/$VM_ID/vm-$VM_ID-disk-0.raw"

# Crear el directorio de la VM si no existe
if [ ! -d "/var/lib/vz/images/$VM_ID" ]; then
    mkdir -p "/var/lib/vz/images/$VM_ID"
fi

# Crear el archivo de disco si no existe
if [ ! -f "$DISK_PATH" ]; then
    echo "Creating the disk file..."
    qemu-img create -f raw "$DISK_PATH" "$DISK_SIZE"
else
    echo "El archivo de disco ya existe."
fi

# Verificar la creación del archivo de disco
if [ -f "$DISK_PATH" ]; then
    echo "Disk file created successfully."
else
    echo "Failed to create the disk file."
    exit 1
fi

# Crear una nueva VM en Proxmox
echo "Creating a new VM in Proxmox..."
qm create $VM_ID --name "$VM_NAME" --memory "$MEMORY" --net0 virtio,bridge="$BRIDGE" --ostype l26 --scsihw virtio-scsi-pci

# Adjuntar el disco a la VM
echo "Attaching the disk to the VM..."
qm set $VM_ID --sata0 "$STORAGE:$VM_ID/vm-$VM_ID-disk-0.raw,size=$DISK_SIZE"

# Verificar la creación y adjunto del disco
if qm config $VM_ID | grep -q "sata0"; then
    echo "SATA disk created and attached successfully."
else
    echo "Failed to create and attach SATA disk."
    exit 1
fi

# Set the CD-ROM
echo "Setting the CD-ROM..."
qm set $VM_ID --ide2 "$STORAGE:iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso,media=cdrom"

# Establecer el orden de arranque para priorizar el CD-ROM primero
echo "Setting boot order..."
qm set $VM_ID --boot order=ide2

# Iniciar la VM
echo "Iniciando la VM..."
qm start $VM_ID

echo "OPNsense VM creado e iniciado exitosamente."
