;;; package-init.el --- settings and functions related to packages
;;; Commentary:
;;; none

;;; Code:

;; package inits
(require 'package)
(setq-default package-enable-at-startup nil)
(add-to-list 'package-archives
  '("melpa" . "https://melpa.org/packages/") t) ;; melpa stable
(package-initialize)

;; helper to install packages if not installed
(defvar package-contents-refreshed nil)
(defun require-package (package)
  "Install a PACKAGE from remote if not installed."
  (unless (package-installed-p package)
    (unless (or package-archive-contents package-contents-refreshed)
      (setq-default package-contents-refreshed t)
      (package-refresh-contents))
    (package-install package)))

(provide 'package-init)
;;; package-init.el ends here
