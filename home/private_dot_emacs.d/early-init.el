;;; early-init.el --- special early init settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; startup speed, annoyance suppression
(setq gc-cons-threshold 10000000)
(setq byte-compile-warnings '(not obsolete))
(setq warning-suppress-log-types '((comp) (bytecomp)))
(setq native-comp-async-report-warnings-errors 'silent)

;; silence stupid startup message
(advice-add #'display-startup-echo-area-message :override #'ignore)

;; tell use-package to install if missing by default
(setq
  use-package-always-ensure t
  use-package-always-defer t)

;; speeds up LSP significantly
(setenv "LSP_USE_PLISTS" "true")

(provide 'early-init)
;;; early-init.el ends here
