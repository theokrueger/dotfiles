;;; features-common-init.el --- init all features -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; builtin
(require 'tabs-init)             ;; top tab bar
(require 'minibuffer-init)       ;; minibuffer settings
(require 'flyspell-init)         ;; spell checking
(require 'dir-locals-init)       ;; per-project settings commands
(require 'desktop-init)          ;; autosave/backup/state settings

;; melpa
(require 'helm-init)             ;; helm settings
(require 'flycheck-init)         ;; flycheck settings
(require 'flyspell-init)         ;; flyspell mode
(require 'company-init)          ;; company settings
(require 'lsp-mode-init)         ;; lsp settings
(require 'format-all-init)       ;; code auto-formatter

(provide 'features-common-init)
;;; features-common-init.el ends here
