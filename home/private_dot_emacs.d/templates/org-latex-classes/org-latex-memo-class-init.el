;;; org-latex-memo-class-init.el --- memo template -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(add-to-list 'org-latex-classes
  '("memo"
     "
% This document class provides a simple and beautiful memo for LaTeX users.
% It is based on scrartcl and inherits most of the functionality
% that class.
%
% Author: Rob Oakes, Copyright 2010.  Released under the LGPL, version 3.
%         Updated by Charles A Taylor and theokrueger
% A copy of the LGPL can be found at http://www.gnu.org/licenses/lgpl.html

\\documentclass{scrartcl}
\\usepackage{geometry}
\\usepackage{indentfirst}

\\geometry{margin=1.0in}

% default packages and custom packages
[DEFAULT-PACKAGES]
[PACKAGES]

% Custom Document Formatting
\\newcommand\\decorativeline[1][1pt]{
	\\par\\noindent%
	\\rule[0.5ex]{\\linewidth}{#1}\\par
}

% override this in header pls
\\def\\@memoto{\\relax}

% Create the Letterhead and To/From Block
\\renewcommand{\\maketitle}{\\makememotitle}
\\newcommand\\makememotitle{
	% To, From, Subject Block
    \\begin{minipage}[b][][b]{1.0\\textwidth}
    	\\begin{description}
    	    \\itemsep=0pt
    	        \\item [{To:}] \\@memoto
    	        \\item [{From:}] \\theauthor
    	        \\item [{Subject:}] \\thetitle
    		\\item [{Date:}] \\thedate
    	\\end{description}
	\\end{minipage}
 	\\decorativeline\\bigskip{}
}

% don't use indented paragraphs, instead use slight breaks
\\KOMAoptions{parskip=half}

\\usepackage[T1]{fontenc}

% use all computer roman fonts for consistency and nice looks
\\addtokomafont{disposition}{\\rmfamily}
\\addtokomafont{descriptionlabel}{\\rmfamily}

% default LaTeX second-level list is ugly
\\renewcommand\\labelitemii{$\\circ$}

% required if you're using LaTeX created by PanDoc
\\providecommand{\\tightlist}{%
  \\setlength{\\itemsep}{0pt}\\setlength{\\parskip}{0pt}}

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

(provide 'org-latex-memo-class-init)
;;; org-latex-memo-class-init.el ends here
