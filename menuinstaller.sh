#!/bin/bash
# Script para seleccionar e instalar sistemas desde GitHub

# Función para mostrar el menú
function show_menu {
    clear
    echo "Seleccione qué desea instalar:"
    echo "1. OPNsense"
    echo "2. Ubuntu"
    echo "3. Debian"
    echo "4. Salir"
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
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Por favor, ingrese un número del 1 al 5."
            read -p "Presione Enter para continuar..."
            ;;
    esac
done
