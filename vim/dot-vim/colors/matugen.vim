" Vim color scheme loader for Matugen dynamic theming
" Loads the generated theme from ~/.config/themes/current/matugen.vim

let s:theme_path = expand("~/.config/themes/current/matugen.vim")
if filereadable(s:theme_path)
    execute "source " . fnameescape(s:theme_path)
else
    " Fallback color scheme if Matugen has not yet generated a palette
    silent! colorscheme synthwave84
endif
