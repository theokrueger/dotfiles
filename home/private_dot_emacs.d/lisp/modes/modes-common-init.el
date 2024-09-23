;;; modes-common-init.el --- common language configuration
;;; Commentary:
;;; Code:

;; shared settings
(setq-default
  c-default-style '(
    (java-mode . "java")
    (awk-mode  . "awk")
    (other     . "linux")
    )
  )

;; loads
(require 'text-mode-init)  ;; text mode settings
(require 'prog-mode-init)  ;; prog mode settings

(require 'cxx-mode-init)   ;; c/c++ settings
(require 'latex-mode-init) ;; latex settings
(require 'lisp-mode-init)  ;; lisp settings
(require 'org-mode-init)   ;; org mode settings
(require 'pdf-mode-init)   ;; pdf viewer settings
(require 'rust-mode-init)  ;; rust settings
(require 'yaml-mode-init)  ;; yaml settings

(provide 'modes-common-init)
;;; modes-common-init.el ends here
