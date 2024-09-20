;;; prog-mode-init.el --- settings for all programming modes
;;; Commentary:
;;; none

;;; Code:

;; indentation settings
(setq-default
  indent-tabs-mode nil ;; spaces over tabs
  default-tab-width 8 ;; 8space tabs
  tab-width 8)

;; rainbow delimiters
(require-package 'rainbow-delimiters)
(use-package rainbow-delimiters
  :defer t
  :commands rainbow-delimiters-mode
  :hook (prog-mode-hook . rainbow-delimiters-mode)
  )

;; indent highlighting
(require-package 'highlight-indent-guides)
(use-package highlight-indent-guides
  :defer t
  :commands highlight-indent-guides-mode
  :hook (prog-mode-hook . highlight-indent-guides-mode)
  )

(provide 'prog-mode-init)
;;; prog-mode-init.el ends here
