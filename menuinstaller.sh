#!/bin/bash
# Script para seleccionar e instalar sistemas desde GitHub

# Función para mostrar el menú
function show_menu {
    clear
    echo "Seleccione qué desea instalar:"
    echo "1. OPNsense"
    echo "2. Ubuntu"
    echo "3. Debian"
    echo "4. Windows Server"
    echo "5. HirenCD"
    echo "6. TrueNAS"
    echo "7. Borrar Contenido Carpeta Isos"
    echo "8. Salir"
    echo
}

# Función para manejar la instalación de OPNsense
function install_opnsense {
    echo "Instalando OPNsense desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/opnsense.sh)"
    echo "OPNsense instalado correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de Ubuntu
function install_ubuntu {
    echo "Instalando Ubuntu desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/ubuntu.sh)"
    echo "Ubuntu instalado correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de Debian
function install_debian {
    echo "Instalando Debian desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/debian.sh)"
    echo "Debian instalado correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de WindowsServer
function install_windows_server {
    echo "Instalando Windows Server desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/windows_server.sh)"
    echo "Windows Server instalado correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de HirenCD
function hirencd {
    echo "Instalando HirenCD desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/hirencd.sh)"
    echo "HironCD Añadido correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de TrueNAS
function truenas {
    echo "Instalando TrueNAS desde GitHub..."
    # Aquí puedes añadir los comandos necesarios para la instalación desde GitHub
    bash -c "$(wget -qLO - https://raw.githubusercontent.com/magoblanco66/proxmox_scripts/main/hirencd.sh)"
    echo "TrueNAS Añadido correctamente."
    read -p "Presione Enter para continuar..."
}

# Función para manejar la instalación de Borrado Isos Proxmox
function borrado_carpeta_isos {
    echo "Borrando contenido carpeta isos de Proxmox..."
    # Aquí puedes añadir los comandos necesarios de la sección
    rm -rf /var/lib/vz/template/iso/*
    echo "Borrada carpeta Isos de Proxmox correctamente."
    read -p "Presione Enter para continuar..."
}

# Bucle principal del script
while true; do
    show_menu
    read -p "Ingrese su selección: " choice
    case $choice in
        1)
            install_opnsense
            ;;
        2)
            install_ubuntu
            ;;
        3)
            install_debian
            ;;
        4)
            install_windows_server
            ;;
        5)
            hirencd
            ;;
        6)
            truenas
            ;;
        7)
            borrado_carpeta_isos
            ;;
        8)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Por favor, ingrese un número del 1 al 7."
            read -p "Presione Enter para continuar..."
            ;;
    esac
done
