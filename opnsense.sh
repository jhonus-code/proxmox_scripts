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

# Variables adicionales para la creación del disco
DISK_PATH="/var/lib/vz/images/$VM_ID/vm-$VM_ID-disk-0.raw"

# Crear el directorio para el disco si no existe
DISK_DIR=$(dirname "$DISK_PATH")
if [ ! -d "$DISK_DIR" ]; then
    echo "Creating the disk directory..."
    mkdir -p "$DISK_DIR"
fi

# Crear el archivo de disco si no existe
if [ ! -f "$DISK_PATH" ]; then
    echo "Creating the disk file..."
    qemu-img create -f raw "$DISK_PATH" "$DISK_SIZE"
fi

# Verificar la creación del archivo de disco
if [ -f "$DISK_PATH" ]; then
    echo "Disk file created successfully."
else
    echo "Failed to create the disk file."
    exit 1
fi

# Download the OPNsense ISO
echo "Downloading OPNsense ISO..."
wget -q "$ISO_URL" -O "$ISO_COMPRESSED"

# Decompress the ISO if not already decompressed
if [ -f "$ISO_UNCOMPRESSED" ]; then
    echo "ISO already decompressed."
else
    echo "Decompressing the ISO..."
    bunzip2 -k "$ISO_COMPRESSED"
fi

# Check if the ISO exists
if [ ! -f "$ISO_UNCOMPRESSED" ]; then
    echo "Failed to download and decompress the OPNsense ISO."
    exit 1
fi

# Create a new VM in Proxmox
echo "Creating a new VM in Proxmox..."
qm create $VM_ID --name "$VM_NAME" --memory "$MEMORY" --net0 virtio,bridge="$BRIDGE" --ostype l26 --scsihw virtio-scsi-pci

# Import the OPNsense ISO to the VM
echo "Importing the OPNsense ISO to the VM..."
qm set $VM_ID --ide2 "$STORAGE:iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso,media=cdrom"

# Adjuntar el disco a la VM
echo "Attaching the disk to the VM..."
qm set $VM_ID --sata0 "$STORAGE:$VM_ID/vm-$VM_ID-disk-0.raw,size=$DISK_SIZE"

# Verify the disk creation and attachment
if qm config $VM_ID | grep -q "sata0"; then
    echo "SATA disk created and attached successfully."
else
    echo "Failed to create and attach SATA disk."
    exit 1
fi

# Set boot order to prioritize the CD-ROM first
echo "Setting boot order..."
qm set $VM_ID --boot order=ide2,sata0

# Start the VM
echo "Starting the VM..."
qm start $VM_ID

echo "OPNsense VM created and started successfully."
