#!/bin/bash
# Copyright (c) 2022-2024 jhonus
# Author: jhonus (telegram)
# License: MIT
# https://github.com/magoblanco66/proxmox_scripts/raw/main/LICENSE

#ASCI Nombre https://www.freetool.dev/es/generador-de-letras-ascii ANSI REGULAR
function header_info {
  clear
  cat <<"EOF"
  
████████ ██████  ██    ██ ███████ ███    ██  █████  ███████ 
   ██    ██   ██ ██    ██ ██      ████   ██ ██   ██ ██      
   ██    ██████  ██    ██ █████   ██ ██  ██ ███████ ███████ 
   ██    ██   ██ ██    ██ ██      ██  ██ ██ ██   ██      ██ 
   ██    ██   ██  ██████  ███████ ██   ████ ██   ██ ███████ 
                                                   
EOF
}
header_info
echo -e "\n Cargando..."

# Clear the contents of the ISO directory
echo "Clearing contents of /var/lib/vz/template/iso/..."
rm -rf /var/lib/vz/template/iso/*

# Variables
# Menu de selección de versión de sistema operativo
echo "Selecciona la versión del sistema operativo que deseas instalar:"
options=("TrueNAS CORE 13.0-U6.1" "TrueNAS SCALE 24.04.1.1" "Salir")
select opt in "${options[@]}"
do
    case $opt in
        "TrueNAS CORE 13.0-U6.1")
            OS_NAME="truenas-core-130"
            OS_VERSION="13.0-U6.1"
            ISO_FILE="TrueNAS-13.0-U6.1.iso"
            ISO_URL="https://download-core.sys.truenas.net/13.0/STABLE/U6.1/x64/${ISO_FILE}"
            break
            ;;
        "TrueNAS SCALE 24.04.1.1")
            OS_NAME="truenas-scale-2404"
            OS_VERSION="24.04.1.1"
            ISO_FILE="TrueNAS-SCALE-24.04.1.1.iso"
            ISO_URL="https://download.sys.truenas.net/TrueNAS-SCALE-Dragonfish/24.04.1.1/${ISO_FILE}"
            break
            ;;
        "Salir")
            echo "Saliendo..."
            exit 0
            ;;
        *) echo "Opción inválida $REPLY";;
    esac
done

# Variables generales
ISO_PATH="/var/lib/vz/template/iso/${ISO_FILE}"
VM_NAME="${OS_NAME//./-}"  # Reemplazar puntos con guiones para nombres válidos
STORAGE="local"
MEMORY="1024"  # Ajusta según los requisitos de tu VM
DISK_SIZE="50G"  # Ajusta según los requisitos de tu VM
BRIDGE="vmbr0"

# Function to get the next available VM ID
get_next_vm_id() {
    local last_id=99  # Establecer el número base para la búsqueda
    for dir in /var/lib/vz/images/*/; do
        dir=${dir%/}  # Eliminar la barra al final
        vm_id=${dir##*/}  # Obtener el número de VM del directorio
        if [[ $vm_id =~ ^[0-9]+$ ]]; then
            if [ $vm_id -gt $last_id ]; then
                last_id=$vm_id
            fi
        fi
    done
    echo $((last_id + 1))  # Devolver el próximo número disponible
}

# Determine the next available VM ID
VM_ID=$(get_next_vm_id)

# Function to download the ISO
download_iso() {
    local url=$1
    echo "Attempting to download ISO from $url..."
    wget $url -O $ISO_PATH
    return $?
}

# Download the ISO if it doesn't exist
if [ ! -f $ISO_PATH ]; then
    download_iso $ISO_URL
    if [ $? -ne 0 ]; then
        echo "Failed to download the ISO from $ISO_URL. Aborting."
        exit 1
    fi
else
    echo "The ISO file $ISO_FILE already exists. Skipping download."
fi

# Verify the ISO integrity
echo "Verifying the integrity of the ISO..."
if ! sudo mount -o loop $ISO_PATH /mnt; then
    echo "Failed to mount the ISO file. Aborting."
    exit 1
fi
sudo umount /mnt

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
if ! qm create $VM_ID --name "$VM_NAME" --memory "$MEMORY" --net0 virtio,bridge="$BRIDGE" --ostype l26 --scsihw virtio-scsi-pci; then
    echo "Failed to create the VM. Aborting."
    exit 1
fi

# Attach the disk to the VM
echo "Attaching the disk to the VM..."
if ! qm set $VM_ID --scsi0 "$STORAGE:$VM_ID/vm-$VM_ID-disk-0.raw,size=$DISK_SIZE"; then
    echo "Failed to attach the disk. Aborting."
    exit 1
fi

# Verify the creation and attachment of the disk
if qm config $VM_ID | grep -q "scsi0"; then
    echo "Disk attached successfully."
else
    echo "Failed to attach the disk. Aborting."
    exit 1
fi

# Set the CD-ROM
echo "Setting the CD-ROM..."
if ! qm set $VM_ID --ide2 "$STORAGE:iso/${ISO_FILE},media=cdrom"; then
    echo "Failed to set the CD-ROM. Aborting."
    exit 1
fi

# Set the boot order to prioritize CD-ROM first
echo "Setting boot order..."
if ! qm set $VM_ID --boot order=ide2; then
    echo "Failed to set the boot order. Aborting."
    exit 1
fi

# Start the VM
echo "Starting the VM..."
if ! qm start $VM_ID; then
    echo "Failed to start the VM. Aborting."
    exit 1
fi

echo "${OS_NAME} VM created and started successfully."
