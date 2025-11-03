#!/bin/bash
set -euo pipefail

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

# --- NUNCA vaciar todas las ISOs automáticamente ---
# echo "Clearing contents of /var/lib/vz/template/iso/..."
# rm -rf /var/lib/vz/template/iso/*

echo "Selecciona la versión de sistema operativo que deseas instalar:"
options=("Windows Server 2016" "Windows Server 2019" "Windows Server 2022" "Windows Server 2025" "Salir")
select opt in "${options[@]}"; do
  case $opt in
    "Windows Server 2016")
      ISO_FILE="windows-server-2016.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x40a&culture=es-es&country=ES"
      break;;
    "Windows Server 2019")
      ISO_FILE="windows-server-2019.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x40a&culture=es-es&country=ES"
      break;;
    "Windows Server 2022")
      ISO_FILE="windows-server-2022.iso"
      ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x40a&culture=es-es&country=ES"
      break;;
    "Windows Server 2025")
      ISO_FILE="windows-server-2025.iso"
      ISO_URL="https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x40a&culture=es-es&country=ES"
      break;;
    "Salir") echo "Saliendo..."; exit 0;;
    *) echo "Opción inválida $REPLY";;
  esac
done

ISO_PATH="/var/lib/vz/template/iso/${ISO_FILE}"

VM_NAME="Server"
MEMORY="4096"
DISK_SIZE="60G"
BRIDGE="vmbr0"
STORAGE_DISK="local-lvm"   # Cambia a tu storage para discos (lvm/zfs/etc.)
STORAGE_ISO="local"        # Storage donde están las ISOs

# Comprobar bridge
if ! grep -q "^auto $BRIDGE" /etc/network/interfaces && ! ip link show "$BRIDGE" >/dev/null 2>&1; then
  echo "ERROR: No existe el bridge $BRIDGE"; exit 1
fi

# Descargar ISO si no existe
if [ ! -f "$ISO_PATH" ]; then
  echo "Descargando ISO desde $ISO_URL ..."
  wget -O "$ISO_PATH" "$ISO_URL"
else
  echo "La ISO $ISO_FILE ya existe. Omitiendo descarga."
fi

# Verificar ISO (monta y desmonta)
echo "Verificando la integridad de la ISO..."
mount -o loop,ro "$ISO_PATH" /mnt || { echo "No se pudo montar la ISO"; exit 1; }
umount /mnt

# Obtener un ID libre de TODO el cluster
echo "Obteniendo un VMID libre..."
if command -v qm >/dev/null 2>&1; then
  VM_ID=$(qm nextid)
else
  echo "No se encontró 'qm'"; exit 1
fi
echo "VM_ID elegido: $VM_ID"

# Crear VM
echo "Creando la VM..."
qm create "$VM_ID" \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --net0 virtio,bridge="$BRIDGE" \
  --ostype win10 \
  --scsihw virtio-scsi-pci

# Crear y adjuntar disco (que lo cree Proxmox en el storage)
echo "Creando y adjuntando el disco..."
qm set "$VM_ID" --scsi0 "$STORAGE_DISK:$DISK_SIZE"

# Adjuntar ISO como CD-ROM
echo "Configurando la ISO como CD-ROM..."
qm set "$VM_ID" --ide2 "$STORAGE_ISO:iso/${ISO_FILE},media=cdrom"

# Orden de arranque: CD primero, luego disco
echo "Estableciendo orden de arranque..."
qm set "$VM_ID" --boot order=ide2;scsi0

# (Opcional) UEFI + Secure Boot desactivado para Windows si lo usas:
# qm set "$VM_ID" --bios ovmf --efidisk0 "$STORAGE_DISK:1,pre-enrolled-keys=0"

# Iniciar VM
echo "Iniciando la VM..."
qm start "$VM_ID"

echo "Windows Server VM creada e iniciada correctamente (VMID: $VM_ID)."
