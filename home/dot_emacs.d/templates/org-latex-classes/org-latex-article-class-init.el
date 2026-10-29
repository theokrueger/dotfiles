;;; org-latex-article-class-init.el --- article template -*- lexical-binding: t -*-
;;; Commentary:
;;; The LaTeX preamble lives in article.tex next to this file, see
;;; org-latex-classes-common-init.el.
;;; Code:

(require 'org-latex-classes-common-init)

;; Declared in ox-latex, which is loaded before this file (see
;; org-latex-classes-init.el); the declaration keeps the byte compiler quiet.
(defvar org-latex-classes)

(add-to-list 'org-latex-classes
  (list "article"
     (org-latex-classes-preamble "article.tex")
     '("\\section{%s}"       . "\\section*{%s}")
     '("\\subsection{%s}"    . "\\subsection*{%s}")
     '("\\subsubsection{%s}" . "\\subsubsection*{%s}")
     '("\\paragraph{%s}"     . "\\paragraph{%s}")
     '("\\subparagraph{%s}"  . "\\subparagraph{%s}")
  )
)

(provide 'org-latex-article-class-init)
;;; org-latex-article-class-init.el ends here
