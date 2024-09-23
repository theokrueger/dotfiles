;;; features-common-init.el --- init all features
;;; Commentary:
;;; Code:

(require 'tabs-init)             ;; top tab bar
(require 'helm-init)             ;; helm settings
(require 'lsp-mode-init)         ;; flycheck settings
(require 'flycheck-init)         ;; flycheck settings
(require 'company-init)          ;; company settings
(require 'undo-tree-init)	 ;; undo tree settings
(require 'format-all-init)	 ;; Code auto-formatter

(provide 'features-common-init)
;;; features-common-init.el ends here
