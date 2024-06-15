#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR
function header_info {
  clear
  cat <<"EOF"
██████  ███████ ██████  ██  █████  ███    ██      ██  ██████      ██  ██     ██████  
██   ██ ██      ██   ██ ██ ██   ██ ████   ██     ███ ██  ████    ███ ███    ██  ████ 
██   ██ █████   ██████  ██ ███████ ██ ██  ██      ██ ██ ██ ██     ██  ██    ██ ██ ██ 
██   ██ ██      ██   ██ ██ ██   ██ ██  ██ ██      ██ ████  ██     ██  ██    ████  ██ 
██████  ███████ ██████  ██ ██   ██ ██   ████      ██  ██████  ██  ██  ██ ██  ██████  
                                                                                                                                       
EOF
}
header_info
echo -e "\n Cargando..."

# Clear the contents of the ISO directory
echo "Clearing contents of /var/lib/vz/template/iso/..."
rm -rf /var/lib/vz/template/iso/*

# Variables
DEBIAN_VERSION="12.5.0"
ISO_FILE="debian-${DEBIAN_VERSION}-amd64-netinst.iso"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/${ISO_FILE}"
ISO_PATH="/var/lib/vz/template/iso/${ISO_FILE}"
VM_ID="108"
VM_NAME="Debian"
STORAGE="local"
MEMORY="1024"  # Ajusta según los requisitos de tu VM
DISK_SIZE="50G"  # Ajusta según los requisitos de tu VM
BRIDGE="vmbr0"

# Function to download the ISO
download_iso() {
    local url=$1
    echo "Attempting to download Debian ISO from $url..."
    wget $url -O $ISO_PATH
    return $?
}

# Download the ISO if it doesn't exist
if [ ! -f $ISO_PATH ]; then
    download_iso $ISO_URL
    if [ $? -ne 0 ]; then
        echo "Failed to download the Debian ISO from $ISO_URL. Aborting."
        exit 1
    fi
else
    echo "The ISO file $ISO_FILE already exists. Skipping download."
fi

# Verify the ISO integrity
echo "Verifying the integrity of the Debian ISO..."
if ! sudo mount -o loop $ISO_PATH /mnt; then
    echo "Failed to mount the ISO file. Aborting."
    exit 1
fi

# Variables for VM creation
DISK_PATH="/var/lib/vz/images/$VM_ID/vm-$VM_ID-disk-0.raw"

# Create the VM directory if it doesn't exist
if [ ! -d "/var/lib/vz/images/$VM_ID" ]; then
    mkdir -p "/var/lib/vz/images/$VM_ID"
fi

# Create the disk file if it doesn't exist
if [ ! -f "$DISK_PATH" ]; then
    echo "Creating the disk file..."
    qemu-img create -f raw "$DISK_PATH" "$DISK_SIZE"
else
    echo "The disk file already exists."
fi

# Verify the creation of the disk file
if [ -f "$DISK_PATH" ]; then
    echo "Disk file created successfully."
else
    echo "Failed to create the disk file."
    exit 1
fi

# Create a new VM in Proxmox
echo "Creating a new VM in Proxmox..."
qm create $VM_ID --name "$VM_NAME" --memory "$MEMORY" --net0 virtio,bridge="$BRIDGE" --ostype l26 --scsihw virtio-scsi-pci

# Attach the disk to the VM
echo "Attaching the disk to the VM..."
qm set $VM_ID --scsi0 "$STORAGE:$VM_ID/vm-$VM_ID-disk-0.raw,size=$DISK_SIZE"

# Verify the creation and attachment of the disk
if qm config $VM_ID | grep -q "scsi0"; then
    echo "Disk attached successfully."
else
    echo "Failed to attach the disk."
    exit 1
fi

# Set the CD-ROM
echo "Setting the CD-ROM..."
qm set $VM_ID --ide2 "$STORAGE:iso/${ISO_FILE},media=cdrom"

# Set the boot order to prioritize CD-ROM first
echo "Setting boot order..."
qm set $VM_ID --boot order=ide2

# Start the VM
echo "Starting the VM..."
qm start $VM_ID

echo "Debian VM created and started successfully."
