;;; company-init.el --- company install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-minimum-prefix-length 1))

(provide 'company-init)
;;; company-init.el ends here
