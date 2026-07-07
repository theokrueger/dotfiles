;;; org-mode-init.el --- org-mode install and settings -*- lexical-binding: t -*-
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
  :init
  ;; values that need to be set before org is loaded
  (setq
    org-confirm-babel-evaluate nil ;; don't confirm org code eval
    org-list-allow-alphabetical t ;; allow lists starting with a. b. c. etc
    )
  (org-babel-do-load-languages
    'org-babel-load-languages
    '(
       (emacs-lisp . t)
       (C . t)
       (python . t)
       (shell . t)
       (java . t)
       (lua . t)
       (js . t)
       (org . t)
       (plantuml . t)
       (latex . t)
       )
    )
  :config
  (add-to-list 'auto-mode-alist '("\\.org$" . org-mode)) ;; associate .org files with org mode
  (setq
    org-hide-emphasis-markers t)
  )

(require-package 'org-bullets)
(use-package org-bullets
  :defer t
  :commands org-bullets-mode
  )

(provide 'org-mode-init)
;;; org-mode-init.el ends here
