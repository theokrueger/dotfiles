;;; lang-common-init.el --- common language configuration
;;; Commentary:
;;; none

;;; Code:

;; 8 space tabs
(setq-default
  indent-tabs-mode nil
  indent-line-function 'insert-tab
  tab-stop-list (number-sequence 8 160 8)
  tab-width 8)
(add-hook 'text-mode-hook
  (lambda() (setq indent-line-function 'insert-tab)))

(provide 'lang-common-init)
;;; lang-common-init.el ends here
