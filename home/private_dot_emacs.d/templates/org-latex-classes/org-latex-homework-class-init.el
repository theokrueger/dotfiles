;;; org-latex-homework-class-init.el --- homework template -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(add-to-list 'org-latex-classes
  '("homework"
"
% page setup
\\documentclass{article}
\\usepackage{geometry}
\\geometry{
  a4paper,
  left=25mm,
  right=25mm,
  top=25mm,
  bottom=25mm
}

% default packages and custom packages
[DEFAULT-PACKAGES]
[PACKAGES]

% subtitle
\\usepackage{titling}
\\newcommand{\\subtitle}[1]{%
  \\newcommand{\\thesubtitle}{#1}
  \\posttitle{%
    \\par\\end{center}
    \\begin{center}\\large#1\\end{center}}%
}

% fancy header
\\usepackage{fancyhdr}
\\lhead{\\theauthor}
\\chead{\\thetitle}
\\rhead{\\thedate}

\\lfoot{\\thesubtitle}
\\cfoot{\\thepage}
\\rfoot{}

\\pagestyle{fancy}

% indent first line after [sub]section
\\usepackage{indentfirst}

% user-defined extra commands
[EXTRA]

% org document begins here
"
     ("\\section{%s}"       . "\\section{%s}")
     ("\\subsection{%s}"    . "\\subsection{%s}")
     ("\\subsubsection{%s}" . "\\subsubsection{%s}")
     ("\\paragraph{%s}"     . "\\paragraph{%s}")
     ("\\subparagraph{%s}"  . "\\subparagraph{%s}")
  )
)

(provide 'org-latex-homework-class-init)
;;; org-latex-homework-class-init.el ends here
