;; package-init.el
;; settings and functions related to packages

;; package inits
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives
  '("melpa" . "https://melpa.org/packages/") t) ;; melpa stable
(package-initialize)

;; better require for remote packages
(defvar package-contents-refreshed nil)
(defun require-package (package)
  "installs a package if not installed, otherwise loads package."
  (unless (package-installed-p package)
    (unless (or package-archive-contents package-contents-refreshed)
      (setq package-contents-refreshed t)
      (package-refresh-contents))
    (package-install package))
  (require package))


;; dont touch this
(provide 'package-init)
