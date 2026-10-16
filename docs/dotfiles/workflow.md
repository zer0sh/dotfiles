# Flujo de Trabajo de Dotfiles

Esta guía explica cómo está organizado el sistema de dotfiles y cómo mantener sincronizadas tus configuraciones entre tu sistema local y GitHub.

---

## 🏛️ Filosofía: Fuente de Verdad Directa

* **Hyprland:** La carpeta `~/.config/hypr` es una **carpeta física real**. Puedes modificar tus archivos directamente sin preocuparte por symlinks o inconsistencias.
* **Repositorio Dotfiles:** La carpeta `~/dotfiles` actúa como el repositorio de control de versiones y copias de seguridad conectado a GitHub (`zer0sh/dotfiles`).

---

## 🔄 Cómo respaldar cambios de Hyprland

Cuando realices ajustes y quieras guardarlos en el repositorio:

1. **Copiar la configuración de Hyprland al repositorio:**
   ```bash
   cp -r ~/.config/hypr/* ~/dotfiles/hypr/
   ```
2. **Revisar cambios y hacer commit:**
   ```bash
   cd ~/dotfiles
   git status
   git add hypr/
   git commit -m "feat(hypr): describir los cambios"
   ```
3. **Subir a GitHub:**
   ```bash
   git push origin main
   ```

---

## 📦 Despliegue de la Documentación (MkDocs)

Para compilar y previsualizar la documentación localmente:

```bash
cd ~/dotfiles
mkdocs serve
```

Para publicar la documentación automáticamente a GitHub Pages:

```bash
cd ~/dotfiles
mkdocs gh-deploy
```
