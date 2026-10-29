;;; org-latex-memo-class-init.el --- memo template -*- lexical-binding: t -*-
;;; Commentary:
;;; The LaTeX preamble lives in memo.tex next to this file, see
;;; org-latex-classes-common-init.el.
;;; Code:

(require 'org-latex-classes-common-init)

;; Declared in ox-latex, which is loaded before this file (see
;; org-latex-classes-init.el); the declaration keeps the byte compiler quiet.
(defvar org-latex-classes)

(add-to-list 'org-latex-classes
  (list "memo"
     (org-latex-classes-preamble "memo.tex")
     '("\\section{%s}"       . "\\section{%s}")
     '("\\subsection{%s}"    . "\\subsection{%s}")
     '("\\subsubsection{%s}" . "\\subsubsection{%s}")
     '("\\paragraph{%s}"     . "\\paragraph{%s}")
     '("\\subparagraph{%s}"  . "\\subparagraph{%s}")
  )
)

(provide 'org-latex-memo-class-init)
;;; org-latex-memo-class-init.el ends here
