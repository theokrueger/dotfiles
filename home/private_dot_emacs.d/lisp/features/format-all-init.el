;;; format-all-init.el --- settings related to format-all package -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require-package 'format-all)

(use-package format-all
  :commands format-all-mode
  :hook (prog-mode . format-all-mode)
  :config
  (setq-default format-all-formatters
    `(
       ("Assembly" asmfmt)
       ("C" (clang-format ,(expand-file-name (format "--style=file:%s/extern/c-linux.clang-format" user-emacs-directory))))
       ("C++" (clang-format ,(expand-file-name (format "--style=file:%s/extern/c-linux.clang-format" user-emacs-directory))))
       ("CSS" prettier)
       ("Emacs Lisp" emacs-lisp)
       ("JavaScript" prettier)
       ("JSON" prettier)
       ("JSON5" prettier)
       ("JSX" prettier)
       ("LaTeX" latexindent)
       ("Markdown" prettier)
       ("Python" black)
       ("Rust" rustfmt)
       ("Shell" shfmt)
       ("TOML" prettier)
       ("TSX" prettier)
       ("TypeScript" prettier)
       ("Vue" prettier)
       ("YAML" prettier)
       ))
  )
(provide 'format-all-init)
;;; format-all-init.el ends here
