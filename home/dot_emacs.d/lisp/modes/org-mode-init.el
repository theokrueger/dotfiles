;;; org-mode-init.el --- org-mode install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package org
  :ensure nil ;; built-in
  :hook
  (org-mode . visual-line-mode) ;; wrap lines
  :bind
  ("C-c <up>"   . org-priority-up)
  ("C-c <down>" . org-priority-down)
  :custom
  ;; values that need to be set before org is loaded
  (org-link-descriptive nil)       ;; show literal links
  (org-confirm-babel-evaluate nil) ;; don't confirm org code eval
  (org-list-allow-alphabetical t)  ;; allow lists starting with a. b. c. etc
  :config
  ;; languages for `org-babel'.
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
  )

;; visually distinct bullets
(declare-function org-superstar-configure-like-org-bullets "org-superstar")
(use-package org-superstar
  :hook (org-mode . org-superstar-mode)
  :config
  (org-superstar-configure-like-org-bullets))

(provide 'org-mode-init)
;;; org-mode-init.el ends here
