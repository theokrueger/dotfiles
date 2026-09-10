;;; format-all-init.el --- settings related to format-all package -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package format-all
  :commands format-all-mode
  :hook (prog-mode . format-all-mode)
  :config
  (setq c-formatter
    ,(format "--style=file:%s" (expand-file-name (format "%s/extern/c-linux.clang-format" user-emacs-directory)))
    )
  (setopt format-all-formatters
    `(
       ("Assembly" asmfmt)
       ("C" (clang-format 'c-formatter))
       ("C++" (clang-format 'c-formatter))
       ("CSS" prettier)
       ("Emacs Lisp" emacs-lisp)
       ("HTML" prettier)
       ("JavaScript" prettier)
       ("JSON" prettier)
       ("JSON5" prettier)
       ("JSX" prettier)
       ("LaTeX" latexindent)
       ("Markdown" prettier)
       ("Python" black)
       ("Rust" (rustfmt "--edition" "2024"))
       ("SCSS" prettier)
       ("Shell" shfmt)
       ("SQL" sqlformat)
       ("TOML" prettier)
       ("TSX" prettier)
       ("TypeScript" prettier)
       ("Verilog" (istyle-verilog "--style=gnu"))
       ("Vue" prettier)
       ("YAML" prettier)
       ))
  )
(provide 'format-all-init)
;;; format-all-init.el ends here
