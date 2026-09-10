;;; lsp-mode-init.el --- settings related to language server protocol -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package lsp-mode
  :commands (
              lsp
              lsp-deferred)
  :hook (prog-mode . lsp-deferred)
  :init
  ;; lsp settings
  (setopt
    lsp-log-io nil         ;; ensure logging off
    lsp-auto-configure t   ;; auto configure lsp ui and such
    lsp-idle-delay 0.500)
  ;; lsp-ui settings
  (setopt
    lsp-ui-peek-always-show t
    lsp-ui-sideline-show-hover t
    lsp-ui-doc-enable nil
    lsp-ui-doc-position "at-point"
    lsp-ui-doc-delay 1.0)
  :bind
  ("C-x n" . lsp-ui-imenu)
  )

(use-package lsp-ui
  :defer t
  :commands lsp-ui-mode)

(use-package helm-lsp
  :defer t
  :commands helm-lsp-workspace-symbol)

(provide 'lsp-mode-init)
;;; lsp-mode-init.el ends here
