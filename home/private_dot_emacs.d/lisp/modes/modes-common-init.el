;;; modes-common-init.el --- common language configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; tree-sitter
(use-package treesit-auto
  :demand t
  :custom
  (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; common
(require 'fundamental-mode-init)  ;; text mode settings
(require 'prog-mode-init)  ;; prog mode settings

;; util
(require 'dired-mode-init) ;; dired mode settings

;; langs
(require 'cxx-mode-init)   ;; c/c++ settings
(require 'latex-mode-init) ;; latex settings
(require 'lisp-mode-init)  ;; lisp settings
(require 'org-mode-init)   ;; org mode settings
(require 'pest-mode-init)  ;; pest settings
(require 'rust-mode-init)  ;; rust settings
(require 'yaml-mode-init)  ;; yaml settings

(provide 'modes-common-init)
;;; modes-common-init.el ends here
