# Dotfiles - Hyprland & Agent Optimized

Este repositorio contiene las configuraciones personales para un entorno de escritorio basado en Hyprland en Debian, diseñado para ser gestionado y mantenido tanto por humanos como por agentes de IA.

## Estructura
- `hypr/`: Configuraciones de Hyprland (modularizadas).
- `waybar/`: Barra de estado.
- `quickshell/`: Shell interactivo personalizado.
- `kitty/`: Emulador de terminal principal.
- `wofi/`: Lanzador de aplicaciones.
- `vim/`: Configuración de Vim (`.vimrc` y plugins).
- `yazi/`, `btop/`, `fastfetch/`, `bat/`: Herramientas de terminal.
- `ai-agent/`: Metadatos e instrucciones para agentes MCP.

## Instalación
Para desplegar estos dotfiles en un nuevo sistema o actualizar los enlaces:
```bash
./install.sh
```
El script realizará backups automáticos de tus configuraciones existentes en `~/.config/*.bak`.

## Requisitos
- **OS:** Debian Trixie (o compatible).
- **WM:** Hyprland.
- **Terminal:** Kitty.
- **Shell:** Zsh/Bash.

## Gestión por IA
Este repo incluye una carpeta `ai-agent/` con configuraciones MCP para permitir que agentes de IA ayuden en la automatización y mantenimiento de los dotfiles.
