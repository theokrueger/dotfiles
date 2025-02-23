;;; early-init.el --- special early init settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; add melpa-stable
(require 'package)
(add-to-list 'package-archives
  '("melpa" . "https://melpa.org/packages/") t)

;; speeds up LSP significantly
(setenv "LSP_USE_PLISTS" "true")

(provide 'early-init)
;;; early-init.el ends here
