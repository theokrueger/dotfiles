;;; org-latex-classes-common-init.el --- helpers for the org latex classes -*- lexical-binding: t -*-
;;; Commentary:
;;; The LaTeX preambles of the org export classes live in .tex files next to
;;; this file, so that they can be edited with LaTeX mode instead of inside
;;; Lisp strings.  `org-latex-classes-preamble' reads such a file when the
;;; class definition is compiled (or loaded, for files that are not
;;; compiled), so a compiled configuration carries the preamble inline and
;;; recompiling is what picks up a changed .tex file.
;;; Code:

(defvar org-latex-classes-directory
  (expand-file-name "templates/org-latex-classes/" user-emacs-directory)
  "Directory holding the .tex preambles of the org export classes.
Only used as a fallback by `org-latex-classes-preamble'.")

(defmacro org-latex-classes-preamble (file)
  "Expand to the contents of FILE, looked up next to the file using it.
The file is read when the macro is expanded, i.e. at compile time for
byte-compiled files and at load time otherwise."
  (let* ((source (or byte-compile-current-file load-file-name))
         (directory (if source
                        (file-name-directory source)
                      org-latex-classes-directory))
         (path (expand-file-name file directory)))
    (unless (file-readable-p path)
      (error "Cannot read LaTeX preamble %s" path))
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string))))

(provide 'org-latex-classes-common-init)
;;; org-latex-classes-common-init.el ends here
