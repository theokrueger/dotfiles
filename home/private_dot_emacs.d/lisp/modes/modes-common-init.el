;;; modes-common-init.el --- common language configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; tree-sitter
(setopt treesit-enabled-modes t              ;; prefer ts-modes where available
  treesit-auto-install-grammar 'ask ;; ask before downloading/building a grammar
  )

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
(require 'python-mode-init) ;; python settings
(require 'rust-mode-init)  ;; rust settings
(require 'yaml-mode-init)  ;; yaml settings

(provide 'modes-common-init)
;;; modes-common-init.el ends here
