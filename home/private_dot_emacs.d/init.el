;;; init.el --- init settings
;;; Commentary:
;;; TODO

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
(add-to-list 'load-path (expand-file-name "lang" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "themes" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "features" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "extern" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "custom" user-emacs-directory))

;; special init
(require 'performance-init)      ;; performance settings
(require 'package-init)          ;; package settings
(require 'util-init)             ;; utility functions
(require 'compile-init)          ;; bytecode compilation for speedup

;; user defined prehooks
(require 'user-prehook)

;; text mode inits
(require 'text-mode-init)        ;; global text editing settings
(require 'prog-mode-init)        ;; settings for all programming modes

;; lang inits
(require 'lang-common-init)      ;; global language settings
(require 'cxx-init)              ;; c/c++ settings
(require 'lisp-init)             ;; lisp settings
(require 'rust-init)             ;; rust settings
(require 'yaml-init)             ;; yaml settings
(require 'lsp-mode-init)         ;; language server protocol
(require 'latex-init)            ;; latex settings

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
(require 'tabs-init)             ;; top tab bar
(require 'helm-init)             ;; helm settings
(require 'flycheck-init)         ;; flycheck settings
(require 'company-init)          ;; company settings
(require 'undo-tree-init)        ;; undo tree settings
(require 'pdf-mode-init)         ;; PDF viewer
(require 'format-all-init)       ;; Code auto-formatter

;; user defined posthooks
(require 'user-posthook)

;; user defined settings
(require 'user-settings)
(setq-default custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

(require 'first-time-setup)    ;; commands to be run on first startup only!!

(provide 'init)
;;; init.el ends here
