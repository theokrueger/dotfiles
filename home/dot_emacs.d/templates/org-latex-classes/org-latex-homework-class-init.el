;;; org-latex-homework-class-init.el --- homework template -*- lexical-binding: t -*-
;;; Commentary:
;;; The LaTeX preamble lives in homework.tex next to this file, see
;;; org-latex-classes-common-init.el.
;;; Code:

(require 'org-latex-classes-common-init)

;; Declared in ox-latex, which is loaded before this file (see
;; org-latex-classes-init.el); the declaration keeps the byte compiler quiet.
(defvar org-latex-classes)

(add-to-list 'org-latex-classes
  (list "homework"
     (org-latex-classes-preamble "homework.tex")
     '("\\section{%s}"       . "\\section{%s}")
     '("\\subsection{%s}"    . "\\subsection{%s}")
     '("\\subsubsection{%s}" . "\\subsubsection{%s}")
     '("\\paragraph{%s}"     . "\\paragraph{%s}")
     '("\\subparagraph{%s}"  . "\\subparagraph{%s}")
  )
)

(provide 'org-latex-homework-class-init)
;;; org-latex-homework-class-init.el ends here
