;;; org-mode-init.el --- org-mode install and settings
;;; Commentary:
;;; Code:


;; associate org mode with .org extensiona
(use-package org-mode
  :defer t
  :commands org-mode
  :hook
  (org-mode . visual-line-mode) ;; wrap lines
  (org-mode . org-bullets-mode) ;; visually distinct bullets
  :bind-keymap
  ("C-c <up>"   . org-priority-up)
  ("C-c <down>" . org-priority-down)
  :config
  (add-to-list 'auto-mode-alist '("\\.org$" . org-mode)) ;; associate .org files with org mode
  (setq-default
    org-hide-emphasis-markers t)
  )

(require-package 'org-bullets)
(use-package org-bullets
  :defer t
  :commands org-bullets-mode
  )

(provide 'org-mode-init)
;;; org-mode-init.el ends here
