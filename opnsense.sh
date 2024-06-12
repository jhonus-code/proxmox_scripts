#!/bin/bash

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

# Download the OPNsense ISO
echo "Downloading OPNsense ISO..."
wget -q "$ISO_URL" -O "$ISO_COMPRESSED"

# Decompress the ISO
echo "Decompressing the ISO..."
bunzip2 -k "$ISO_COMPRESSED"

# Check if the ISO exists
if [ ! -f "$ISO_UNCOMPRESSED" ]; then
    echo "Failed to download and decompress the OPNsense ISO."
    exit 1
fi

# Create a new VM in Proxmox
echo "Creating a new VM in Proxmox..."
qm create $VM_ID --name "$VM_NAME" --memory "$MEMORY" --net0 virtio,bridge="$BRIDGE" --bootdisk virtio0 --ostype l26

# Import the OPNsense disk to the VM
echo "Importing the OPNsense disk to the VM..."
import_result=$(qm importdisk $VM_ID "$ISO_UNCOMPRESSED" "$STORAGE" 2>&1)

# Check if import was successful
if [[ $import_result == *"successfully imported"* ]]; then
    echo "Disk imported successfully."
else
    echo "Failed to import disk: $import_result"
    exit 1
fi

# Configure the VM to use the imported disk
echo "Configuring the VM..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$VM_ID-disk-0"
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --ide2 "$STORAGE:iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso,media=cdrom"

# Resize the disk to the desired size
echo "Resizing the disk to $DISK_SIZE..."
qm resize $VM_ID scsi0 "$DISK_SIZE"

# Start the VM
echo "Starting the VM..."
qm start $VM_ID

echo "OPNsense VM created and started successfully."
