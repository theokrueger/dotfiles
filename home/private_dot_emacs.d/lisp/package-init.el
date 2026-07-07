;;; package-init.el --- settings and functions related to packages -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; package inits
(setq package-enable-at-startup nil)

;; helper to install packages if not installed
(defvar package-contents-refreshed nil)
(defun require-package (package)
  "Install a PACKAGE from remote if not installed."
  (interactive)
  (unless (package-installed-p package)
    (unless (or package-archive-contents package-contents-refreshed)
      (setq package-contents-refreshed t)
      (package-refresh-contents))
    (package-install package)))

(provide 'package-init)
;;; package-init.el ends here
