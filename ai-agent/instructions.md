# Instrucciones para Agentes IA (Dotfiles Manager)

Este repositorio contiene la configuración del sistema (dotfiles) y está optimizado para ser gestionado por IAs mediante MCP (Model Context Protocol).

## Roles y Responsabilidades
- **Mantenimiento:** Al realizar cambios, actualiza siempre la documentación en `README.md` o los archivos de documentación específicos del módulo.
- **Seguridad:** NUNCA subas secretos, API keys o información sensible. Usa archivos `.env` o `.gitignore` adecuadamente.
- **Estructura:** Mantén la estructura modular de Hyprland. Si añades una nueva categoría, crea un nuevo archivo `.conf` y añádelo a `hyprland.conf`.

## Flujo de Trabajo
1. **Investigar:** Leer los archivos actuales y entender la intención antes de modificar.
2. **Proponer:** Explicar el cambio al usuario antes de ejecutarlo si es disruptivo.
3. **Validar:** Asegurarse de que la sintaxis de Hyprland sea correcta.
4. **Documentar:** Reflejar los cambios en los `README.md` correspondientes.

## Servidores MCP Sugeridos
- `filesystem`: Para leer y escribir configuraciones.
- `git`: Para control de versiones y trazabilidad de cambios.
