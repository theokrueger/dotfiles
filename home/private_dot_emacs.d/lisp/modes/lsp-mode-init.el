;;; lsp-mode-init.el --- settings related to language server protocol
;;; Commentary:
;;; Code:

(require-package 'lsp-mode)
(use-package lsp-mode
  :defer t
  :commands (
              lsp
              lsp-deferred)
  ;;  :hook (prog-mode . lsp-deferred)
  :init
  ;; lsp settings
  (setq-default
    lsp-log-io nil         ;; ensure logging off
    lsp-auto-configure nil ;; no auto configure lsp ui and such
    lsp-idle-delay 0.500)
  ;; lsp-ui settings
  (setq-default
    lsp-ui-peek-always-show t
    lsp-ui-sideline-show-hover t
    lsp-ui-doc-enable nil
    lsp-ui-doc-position "at-point"
    lsp-ui-doc-delay 1.0)
  :bind
  ("C-x n" . lsp-ui-imenu)
  )

(require-package 'lsp-ui)
(use-package lsp-ui
  :defer t
  :commands lsp-ui-mode)

(require-package 'helm-lsp)
(use-package helm-lsp
  :defer t
  :commands helm-lsp-workspace-symbol)

(provide 'lsp-mode-init)
;;; lsp-mode-init.el ends here
