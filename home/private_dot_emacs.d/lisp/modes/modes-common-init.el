;;; modes-common-init.el --- common language configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; shared settings
(setq-default
  c-default-style '(
    (java-mode . "java")
    (awk-mode  . "awk")
    (other     . "linux")
    )
  )

;; tree-sitter
(require-package 'treesit-auto)
(use-package treesit-auto
  :custom
  (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; loads
(require 'text-mode-init)  ;; text mode settings
(require 'prog-mode-init)  ;; prog mode settings

(require 'cxx-mode-init)   ;; c/c++ settings
(require 'latex-mode-init) ;; latex settings
(require 'lisp-mode-init)  ;; lisp settings
(require 'org-mode-init)   ;; org mode settings
(require 'rust-mode-init)  ;; rust settings
(require 'yaml-mode-init)  ;; yaml settings
(require 'pest-mode-init)  ;; pest settings

(provide 'modes-common-init)
;;; modes-common-init.el ends here
