;;; init.el --- init settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; debug
(setq-default debug-on-error nil) ;; debug traces

;; prereqs
(let ((minver "28.2"))
  (if (version< emacs-version minver)
    (error "Emacs is too old.  Upgrade to Emacs %s to use this config" minver)))

;; unset `file-name-handler-alist` for performance
(defvar fnh-alist-old (default-toplevel-value 'file-name-handler-alist))
(setq-default file-name-handler-alist nil)

;; load paths
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "modes" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "themes" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "features" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "extern" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "custom" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "templates" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "org-latex-classes" (concat user-emacs-directory "/templates")))

;; special init
(require 'package-init)          ;; package settings
(require 'util-init)             ;; utility functions
(require 'performance-init)      ;; performance settings
(require 'compile-init)          ;; bytecode compilation for speedup

;; user defined prehooks
(require 'user-prehook)

;; lang inits
(require 'modes-common-init)     ;; global mode settings

;; interface inits
(require 'inhibit-messages-init) ;; suppress fanfare
(require 'gui-init)              ;; GUI window settings
(require 'tui-init)              ;; TUI settings
(require 'themes-init)           ;; colour / theme settings

;; interaction inits
(require 'keybinds-init)         ;; custom keybinds
(require 'desktop-init)          ;; desktop save/loading, backups
(require 'time-init)             ;; measure startup time

;; feature inits
(require 'features-common-init)  ;; feature settings

;; templates init
(require 'templates-common-init) ;; templates

;; user settings init
(require 'user-posthook)

;; user defined settings
(setq-default custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

(require 'first-time-setup)    ;; commands to be run on first startup only!!

(provide 'init)
;;; init.el ends here
