#!/usr/bin/env bash

# Configuration variables
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

# Descargar la imagen ISO de OPNsense
echo "Descargando OPNsense ISO..."
wget $ISO_URL -O $ISO_COMPRESSED

# Descomprimir la imagen ISO
echo "Descomprimiendo el ISO..."
bunzip2 $ISO_COMPRESSED

# Verificar que la ISO existe
if [ ! -f $ISO_UNCOMPRESSED ]; then
    echo "No se pudo descargar y descomprimir el ISO de OPNsense."
    exit 1
fi

function header_info {
  clear
  cat <<"EOF"
   __  ____                __           ___  __ __   ____  __ __     _    ____  ___
  / / / / /_  __  ______  / /___  __   |__ \/ // /  / __ \/ // /    | |  / /  |/  /
 / / / / __ \/ / / / __ \/ __/ / / /   __/ / // /_ / / / / // /_    | | / / /|_/ /
/ /_/ / /_/ / /_/ / / / / /_/ /_/ /   / __/__  __// /_/ /__  __/    | |/ / /  / /
\____/_.___/\__,_/_/ /_/\__/\__,_/   /____/ /_/ (_)____/  /_/       |___/_/  /_/

EOF
}
header_info
echo -e "\n Loading..."
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
NEXTID=$(pvesh get /cluster/nextid)

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
HA=$(echo "\033[1;34m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
THIN="discard=on,ssd=1,"
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function cleanup_v
bash
Copiar código
#!/usr/bin/env bash

# Configuration variables
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

# Descargar la imagen ISO de OPNsense
echo "Descargando OPNsense ISO..."
wget $ISO_URL -O $ISO_COMPRESSED

# Descomprimir la imagen ISO
echo "Descomprimiendo el ISO..."
bunzip2 $ISO_COMPRESSED

# Verificar que la ISO existe
if [ ! -f $ISO_UNCOMPRESSED ]; then
    echo "No se pudo descargar y descomprimir el ISO de OPNsense."
    exit 1
fi

function header_info {
  clear
  cat <<"EOF"
   __  ____                __           ___  __ __   ____  __ __     _    ____  ___
  / / / / /_  __  ______  / /___  __   |__ \/ // /  / __ \/ // /    | |  / /  |/  /
 / / / / __ \/ / / / __ \/ __/ / / /   __/ / // /_ / / / / // /_    | | / / /|_/ /
/ /_/ / /_/ / /_/ / / / / /_/ /_/ /   / __/__  __// /_/ /__  __/    | |/ / /  / /
\____/_.___/\__,_/_/ /_/\__/\__,_/   /____/ /_/ (_)____/  /_/       |___/_/  /_/

EOF
}
header_info
echo -e "\n Loading..."
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
NEXTID=$(pvesh get /cluster/nextid)

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
HA=$(echo "\033[1;34m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
THIN="discard=on,ssd=1,"
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function cleanup_vmid() {
  if [ -n "$VMID" ]; then
    qm destroy "$VMID" --purge
    echo -e "${DGN}Cleaned up VMID $VMID${CL}"
  fi
}

function cleanup() {
  unset VMID
}

function default_settings() {
  VMID=$NEXTID
  CORES=2
  RAM=2048
  BRIDGE="vmbr0"
  FORMAT=",efitype=4m"
  DISK_CACHE=",cache=writethrough,"
  CPU_TYPE=""
  MACHINE=""
  VLAN=""
  MTU=""
}

function advanced_settings() {
  if VMID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set VM ID" 8 58 $NEXTID --title "VM ID" 3>&1 1>&2 2>&3); then
    if [ -z "$VMID" ]; then
      VMID=$NEXTID
    fi
    echo -e "${DGN}Using VM ID: ${BGN}$VMID${CL}"
  else
    exit-script
  fi

  if MACH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "MACHINE TYPE" --radiolist --cancel-button Exit-Script "Choose Machine Type" 10 58 2 \
    "i440fx" "Default Machine" ON \
    "q35" "Q35 Machine" OFF \
    3>&1 1>&2 2>&3); then
    echo -e "${DGN}Using Machine Type: ${BGN}$MACH${CL}"
    if [ "$MACH" == "q35" ]; then
      FORMAT=",efitype=4m"
      MACHINE=" -machine q35"
    fi
  else
    exit-script
  fi

  if DISK=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DISK CACHE" --radiolist --cancel-button Exit-Script "Choose Disk Cache" 10 58 2 \
    "none" "No Cache" ON \
    "writeback" "Writeback Cache" OFF \
    3>&1 1>&2 2>&3); then
    echo -e "${DGN}Using Disk Cache: ${BGN}$DISK${CL}"
    if [ "$DISK" == "writeback" ]; then
      DISK_CACHE=",cache=writethrough,"
    fi
  else
    exit-script
  fi

  if HN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 opnsense --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$HN" ]; then
      HN="opnsense"
    fi
    echo -e "${DGN}Using Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if CPU=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU MODEL" --radiolist --cancel-button Exit-Script "Choose CPU Model" 10 58 2 \
    "default" "Default" ON \
    "host" "KVM64" OFF \
    3>&1 1>&2 2>&3); then
    if [ "$CPU" == "default" ]; then
      CPU_TYPE=""
      echo -e "${DGN}Using CPU Model: ${BGN}Default${CL}"
    else
      CPU_TYPE="host"
      echo -e "${DGN}Using CPU Model: ${BGN}$CPU_TYPE${CL}"
    fi
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 2 --title "CORE COUNT" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then
      CORE_COUNT="2"
    fi
    echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB" 8 58 2048 --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_SIZE" ]; then
      RAM_SIZE="2048"
    fi
    echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface Bridge" 8 58 vmbr0 --title "BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then
      BRG="vmbr0"
    fi
    echo -e "${DGN}Using Bridge: ${BGN}$BRG${CL}"
  else
    exit-script
  fi

  if MAC=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set MAC Address" 8 58 $GEN_MAC --title "MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$MAC" ]; then
      MAC="$GEN_MAC"
    fi
    echo -e "${DGN}Using MAC Address: ${BGN}$MAC${CL}"
  else
    exit-script
  fi

  if VLAN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set VLAN ID (Leave Blank for Default)" 8 58 --title "VLAN" 3>&1 1>&2 2>&3); then
    echo -e "${DGN}Using VLAN ID: ${BGN}$VLAN${CL}"
    if [ -n "$VLAN" ]; then
      VLAN=",tag=$VLAN"
    else
      VLAN=""
    fi
  fi

  if MTU=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set MTU Size (Leave Blank for Default)" 8 58 --title "MTU" 3>&1 1>&2 2>&3); then
    echo -e "${DGN}Using MTU Size: ${BGN}$MTU${CL}"
    if [ -n "$MTU" ]; then
      MTU=",mtu=$MTU"
    else
      MTU=""
    fi
  fi
}

default_settings

qm create "$VMID" -agent 1${MACHINE} -cores "$CORE_COUNT" -memory "$RAM_SIZE" -name "$VM_NAME" -net0 virtio,bridge="$BRG",macaddr="$MAC"$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci -sockets 1

qm set "$VMID" -efidisk0 "$STORAGE:vm-$VMID-disk-1,size=128K$FORMAT"
qm importdisk "$VMID" "$ISO_UNCOMPRESSED" "$STORAGE" --format qcow2
qm set "$VMID" -scsi0 "$STORAGE:vm-$VMID-disk-1$DISK_CACHE,format=qcow2"
qm set "$VMID" -boot c -bootdisk scsi0
qm set "$VMID" -serial0 socket
qm set "$VMID" -vga qxl
qm set "$VMID" -cdrom "$STORAGE:iso/OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso"

echo -e "${GN}VM $VMID has been successfully created and configured.${CL}"
