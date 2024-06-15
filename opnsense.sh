#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR
function header_info {
  clear
  cat <<"EOF"
 ██████  ██████  ███    ██ ███████ ███████ ███    ██ ███████ ███████ 
██    ██ ██   ██ ████   ██ ██      ██      ████   ██ ██      ██      
██    ██ ██████  ██ ██  ██ ███████ █████   ██ ██  ██ ███████ █████   
██    ██ ██      ██  ██ ██      ██ ██      ██  ██ ██      ██ ██      
 ██████  ██      ██   ████ ███████ ███████ ██   ████ ███████ ███████ 
                                                   
EOF
}
header_info
echo -e "\n Cargando..."

# Clear the contents of the ISO directory
echo "Clearing contents of /var/lib/vz/template/iso/..."
rm -rf /var/lib/vz/template/iso/*

# Variables
OPNSENSE_VERSION="24.1"
PRIMARY_ISO_URL="https://mirror.dns-root.de/opnsense/releases/${OPNSENSE_VERSION}/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso.bz2"
BACKUP_ISO_URL="https://opnsense.c0urier.net/releases/${OPNSENSE_VERSION}/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso.bz2"
ISO_COMPRESSED="/var/lib/vz/template/iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso.bz2"
ISO_UNCOMPRESSED="/var/lib/vz/template/iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso"
VM_ID="108"
VM_NAME="OPNsense"
STORAGE="local"
MEMORY="512"
DISK_SIZE="32G"
BRIDGE="vmbr0"

# Function to download the ISO
download_iso() {
    local url=$1
    echo "Attempting to download OPNsense ISO from $url..."
    wget $url -O $ISO_COMPRESSED
    return $?
}

# Download the ISO if it doesn't exist
if [ ! -f $ISO_COMPRESSED ]; then
    download_iso $PRIMARY_ISO_URL
    if [ $? -ne 0 ]; then
        echo "Primary URL failed. Attempting to download from backup URL..."
        download_iso $BACKUP_ISO_URL
        if [ $? -ne 0 ]; then
            echo "Failed to download the ISO from both primary and backup URLs. Verify the URLs or the internet connection."
            exit 1
        fi
    fi
else
    echo "El archivo comprimido ya existe. No se descargará nuevamente."
fi

# Verify the ISO integrity
echo "Verificando la integridad del archivo ISO..."
bunzip2 -t $ISO_COMPRESSED
if [ $? -ne 0 ]; then
    echo "El archivo ISO está corrupto o incompleto. Volviendo a descargar..."
    rm -f $ISO_COMPRESSED
    download_iso $PRIMARY_ISO_URL
    if [ $? -ne 0 ]; then
        download_iso $BACKUP_ISO_URL
        if [ $? -ne 0 ]; then
            echo "La descarga del archivo ISO falló nuevamente. Abortando."
            exit 1
        fi
    fi
    bunzip2 -t $ISO_COMPRESSED
    if [ $? -ne 0 ]; then
        echo "La verificación del archivo ISO falló nuevamente. Abortando."
        exit 1
    fi
fi

# Descomprimir la imagen ISO si no está descomprimida
if [ -f $ISO_COMPRESSED ] && [ ! -f $ISO_UNCOMPRESSED ]; then
    echo "Descomprimiendo el ISO..."
    bunzip2 $ISO_COMPRESSED
    if [ $? -ne 0 ]; then
        echo "Fallo al descomprimir el archivo ISO."
        exit 1
    fi
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
