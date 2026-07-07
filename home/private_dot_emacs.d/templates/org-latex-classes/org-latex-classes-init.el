;;; org-latex-classes-init.el --- load templates for org latex -*- lexical-binding: t -*-
;;; Commentary:
;;; Loaded by org-mode-init.el
;;; Code:

(require-package 'engrave-faces)

;; add classes
(with-eval-after-load 'ox-latex
  (setq org-latex-packages-alist '())

  ;; use engraved for code blocks
  (setq org-latex-src-block-backend 'engraved)
  (add-to-list 'org-latex-default-packages-alist'("" "fvextra" nil))
  (add-to-list 'org-latex-default-packages-alist'("" "titling" nil))

  ;; latex output settings
  (setq-default
    org-latex-tables-centered nil
    org-latex-subtitle-separate t
    org-latex-subtitle-format "\\subtitle{%s}"
    org-latex-title-command "\\maketitle")

  ;; modify default classes
  (require 'org-latex-article-class-init)

  ;; add custom classes
  (require 'org-latex-homework-class-init)
  (require 'org-latex-memo-class-init)
  )

(provide 'org-latex-classes-init)
;;; org-latex-classes-init.el ends here
