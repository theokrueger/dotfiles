;; early-init.el
;; early init settings

;; debug
(setq debug-on-error nil) ;; debug traces

;; prereqs
(let ((minver "28.2"))
  (if (version< emacs-version minver)
    (error "Emacs is too old. Upgrade to emacs %s to use this config." minver)))

;; unset `file-name-handler-alist` for performance
(defvar fnh-alist-old (default-toplevel-value 'file-name-handler-alist))
(setq file-name-handler-alist nil)

;; load paths
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lang" (concat user-emacs-directory "/lisp")))
(add-to-list 'load-path (expand-file-name "themes" (concat user-emacs-directory "/lisp")))
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
(require 'cxx-init)              ;; c/c++ settings
(require 'lisp-init)             ;; lisp settings
(require 'lua-init)              ;; lua settings
(require 'rust-init)             ;; rust settings
(require 'yaml-init)             ;; yaml settings
(require 'lsp-mode-init)         ;; language server protocol

;; interface inits
(require 'inhibit-messages-init) ;; suppress fanfare
(require 'tabs-init)             ;; top tab bar
(require 'sidebar-init)          ;; sidebar settings
(require 'helm-init)             ;; helm settings
(require 'gui-init)              ;; X window settings
(require 'themes-init)            ;; colour / theme settings

;; interaction inits
(require 'keybinds-init)         ;; custom keybinds
(require 'desktop-init)          ;; desktop save/loading, backups
(require 'time-init)             ;; measure startup time

;; register for emacsclient
(add-hook 'after-init-hook
  (lambda ()
    (require 'server)
    (unless (server-running-p)
      (server-start))))

;; user defined posthooks
(require 'user-posthook)

;; user defined settings
(require 'user-settings)
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

(require 'first-time-setup)    ;; commands to be run on first startup only!!

;; revert `file-name-handler-alist` for performance
(setq file-name-handler-alist
  ;; merge instead of overwrite
  (delete-dups (append file-name-handler-alist fnh-alist-old)))
(makunbound 'fnh-alist-old)

;; dont touch this
(provide 'early-init)
