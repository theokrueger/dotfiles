;;; dir-locals-init.el --- per-project settings via dir-locals files -*- lexical-binding: t -*-
;;; Commentary:
;;; Commands that record per-project settings in `.dir-locals-2.el', the
;;; personal dir-locals file.  That file is the only one these commands ever
;;; touch: no `.dir-locals.el' companion and no `.git/info/exclude' entries are
;;; written, so the repository is left alone.
;;;
;;; The settings are plain variables, declared safe below so that Emacs never
;;; asks whether to apply them.  They are acted upon by
;;; `dir-locals-project--apply' from `hack-local-variables-hook': the
;;; `prog-mode-hook' functions that enable the modes in question run *before*
;;; the dir-locals are read, so the work has to happen afterwards.
;;;
;;; Recording a setting therefore does not change the current buffer; it takes
;;; effect the next time a file of that project is visited.
;;; Code:

(defgroup dir-locals-project nil
  "Per-project settings stored in dir-locals files."
  :group 'convenience)

(declare-function c-ts-mode-set-style "c-ts-mode" (style))
(declare-function format-all-mode "format-all" (&optional arg))
(declare-function project-root "project" (project))

;; lsp-mode is loaded on demand (see lsp-mode-init.el), so the compiler
;; needs to be told about the parts used below.
(declare-function lsp--client-server-id "lsp-mode" (client))
(declare-function lsp--filter-clients "lsp-mode" (pred))
(declare-function lsp--init-if-visible "lsp-mode" ())
(declare-function lsp--require-packages "lsp-mode" ())
(declare-function lsp--supports-buffer? "lsp-mode" (client))
(declare-function lsp-disconnect "lsp-mode" ())
(declare-function lsp-workspaces "lsp-mode" ())
(defvar lsp--buffer-deferred)
(defvar lsp-disabled-clients)
(defvar lsp-warn-no-matched-clients)

(defcustom dir-locals-project-file ".dir-locals-2.el"
  "Dir-locals file written by the `dir-locals-project-*' commands.
Emacs reads it after the project's `.dir-locals.el', so its settings take
precedence.  It is meant for personal settings and should not be committed."
  :type 'string
  :group 'dir-locals-project)

;;; Settings read from the dir-locals file

(defvar dir-locals-project-formatting t
  "Whether to format this project's buffers on save.
Set to nil in a dir-locals file to keep `format-all-mode' from running.")
(put 'dir-locals-project-formatting 'safe-local-variable #'booleanp)

(defvar dir-locals-project-format-style 'default
  "Indentation style to use for this project.
`default'   keep the style from `format-all-init.el' (8 columns, spaces)
`spaces-4'  indent with 4 spaces
`tabs'      indent with tabs, 8 columns wide
`project'   use the project's own formatter configuration (`.clang-format',
            `.editorconfig', `rustfmt.toml', ...) where the formatter
            supports it; indentation in Emacs is left alone.")
(put 'dir-locals-project-format-style
  'safe-local-variable (lambda (value) (memq value '(default spaces-4 tabs project))))

(defvar dir-locals-project-whitespace t
  "Whether to clean up and highlight whitespace in this project.")
(put 'dir-locals-project-whitespace 'safe-local-variable #'booleanp)

(defvar dir-locals-project-lsp t
  "Whether to start language servers in this project.
Set to nil in a dir-locals file for code bases where a language server is
unavailable, unwanted or too expensive.")
(put 'dir-locals-project-lsp 'safe-local-variable #'booleanp)

;;; Applying the settings

(defun dir-locals-project--apply ()
  "Apply the `dir-locals-project-*' settings in the current buffer."
  (when (eq dir-locals-project-formatting nil)
    (dir-locals-project--disable-formatting))
  (unless (eq dir-locals-project-format-style 'default)
    (dir-locals-project--set-style dir-locals-project-format-style))
  (when (eq dir-locals-project-whitespace nil)
    (dir-locals-project--disable-whitespace))
  (when (eq dir-locals-project-lsp nil)
    (dir-locals-project--disable-lsp)))

(defun dir-locals-project--disable-formatting ()
  "Turn off formatting on save in the current buffer."
  (when (fboundp 'format-all-mode)
    (format-all-mode -1)))

(defun dir-locals-project--disable-whitespace ()
  "Stop cleaning up and highlighting whitespace in the current buffer."
  (dolist (minor-mode '(whitespace-cleanup-mode whitespace-mode))
    (when (and (fboundp minor-mode) (bound-and-true-p minor-mode))
      (funcall minor-mode -1)))
  (setq-local show-trailing-whitespace nil))

(defun dir-locals-project--disable-lsp ()
  "Keep the language servers the current buffer would use from starting."
  (require 'lsp-mode)
  ;; Language servers are only registered once their client libraries are
  ;; loaded, which is what `lsp' itself does first.
  (lsp--require-packages)
  ;; `lsp-deferred' has already scheduled its start by now (it runs from
  ;; `prog-mode-hook'), so cancel it and stop lsp-mode from complaining about
  ;; the missing clients.
  (setq-local lsp--buffer-deferred nil)
  (remove-hook 'window-configuration-change-hook #'lsp--init-if-visible t)
  (setq-local lsp-warn-no-matched-clients nil)
  ;; Only check which clients *support* the buffer: `lsp--find-clients' also
  ;; checks whether the server binaries are installed, which can prompt to
  ;; download them.
  (when-let* ((clients (mapcar #'lsp--client-server-id
                         (lsp--filter-clients #'lsp--supports-buffer?))))
    (setq-local lsp-disabled-clients
      (delete-dups (append clients lsp-disabled-clients))))
  ;; Take effect right away if a server is already running for this buffer.
  (when (lsp-workspaces)
    (lsp-disconnect)))

(defconst dir-locals-project--indent-variables
  '(standard-indent
     c-basic-offset
     c-ts-indent-offset
     rust-indent-offset
     rust-ts-indent-offset
     python-indent-offset
     sh-basic-offset
     sh-indentation
     js-indent-level
     js-jsx-indent-level
     css-indent-offset
     sgml-basic-offset
     nxml-child-indent
     go-ts-indent-offset
     ruby-indent-level)
  "Indentation options set by `dir-locals-project--set-style'.")

(defun dir-locals-project--clang-style (style)
  "Return the clang-format `--style' argument for indentation STYLE."
  (pcase style
    ('spaces-4 "{BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ContinuationIndentWidth: 4}")
    ('tabs "{BasedOnStyle: LLVM, IndentWidth: 8, TabWidth: 8, UseTab: Always, ContinuationIndentWidth: 8}")
    (_ "file")))

(defun dir-locals-project--formatters (style)
  "Return a `format-all-formatters' value for indentation STYLE.
Only the formatters whose indentation is configurable on the command line
are adjusted; `black' (always 4 spaces) and `rustfmt' (configured in
`rustfmt.toml') are left as they are."
  (when (boundp 'format-all-formatters)
    (let ((width (if (eq style 'spaces-4) "4" "8"))
           (project (eq style 'project)))
      (mapcar
        (lambda (entry)
          (cons (car entry)
            (mapcar
              (lambda (formatter)
                (pcase formatter
                  (`(clang-format . ,_)
                    (list 'clang-format
                      (concat "--style="
                        (if project
                          "file"
                          (dir-locals-project--clang-style style)))))
                  (`(prettier . ,_)
                    (append (list 'prettier)
                      (unless project (list "--tab-width" width))
                      (when (eq style 'tabs) (list "--use-tabs"))))
                  (`(shfmt . ,_)
                    (if project
                      formatter
                      (list 'shfmt "-i" (if (eq style 'tabs) "0" width))))
                  (_ formatter)))
              (cdr entry))))
        (default-value 'format-all-formatters)))))

(defun dir-locals-project--set-style (style)
  "Use indentation STYLE in the current buffer."
  ;; Indentation in Emacs itself.
  (unless (eq style 'project)
    (let ((tabs (eq style 'tabs))
           (width (if (eq style 'spaces-4) 4 8)))
      (setq-local indent-tabs-mode tabs)
      (setq-local tab-width width)
      ;; `setq-local' would quote the loop variable, so set the
      ;; buffer-local value dynamically instead.
      (dolist (indent-var dir-locals-project--indent-variables)
        (when (boundp indent-var)
          (set (make-local-variable indent-var) width)))))
  (when (derived-mode-p 'c-ts-mode 'c++-ts-mode)
    (c-ts-mode-set-style (if (eq style 'tabs) 'linux 'k&r)))
  ;; Formatting on save.
  (when-let* ((formatters (dir-locals-project--formatters style)))
    (setq-local format-all-formatters formatters)))

(add-hook 'hack-local-variables-hook #'dir-locals-project--apply)

;;; Locating the dir-locals file

(defun dir-locals-project--root ()
  "Return the root directory of the current project."
  (or (when-let* ((project (project-current nil)))
        (project-root project))
    (locate-dominating-file default-directory ".git")
    default-directory))

(defun dir-locals-project--file ()
  "Return this project's dir-locals file."
  (expand-file-name dir-locals-project-file (dir-locals-project--root)))

(defun dir-locals-project--base-file (directory)
  "Return readable dir-locals file in DIRECTORY, or nil.
Like `dir-locals--base-file', except that a directory holding only the
personal `dir-locals-project-file' also counts.  `dir-locals-find-file'
searches upward with this to decide where the dir-locals of a file live, and
the unadvised version insists on a `.dir-locals.el', which would otherwise
have to be created in every project."
  (or (dir-locals--all-files directory 'base-el-only)
    (dir-locals--all-files directory)))

(advice-add 'dir-locals--base-file :override #'dir-locals-project--base-file)

;;; Writing the dir-locals file

(defun dir-locals-project--set (setting value)
  "Record SETTING with VALUE for all modes in this project's dir-locals file."
  ;; `add-dir-local-variable' visits the file and leaves it modified for
  ;; review, which is not what these commands are for: save it, and let
  ;; `save-window-excursion' put the window configuration back.
  (save-window-excursion
    (add-dir-local-variable nil setting value (dir-locals-project--file))
    (when (buffer-modified-p)
      (save-buffer)))
  (message "%s is now %S for %s (takes effect on the next visit)"
    setting value (abbreviate-file-name (dir-locals-project--root))))

;;; Commands

(defun dir-locals-project-toggle-formatting ()
  "Toggle formatting on save for this project."
  (interactive)
  (let ((value (not dir-locals-project-formatting)))
    (setq-local dir-locals-project-formatting value)
    (dir-locals-project--set 'dir-locals-project-formatting value)))

(defun dir-locals-project-set-format-style (style)
  "Set the indentation style used for this project to STYLE."
  (interactive
    (list (intern (completing-read
                    "Indentation for this project: "
                    '(("spaces-4" . "4 spaces")
                       ("tabs" . "tabs, 8 columns")
                       ("project" . "the project's own configuration")
                       ("default" . "this configuration's style"))
                    nil t nil nil "spaces-4"))))
  (setq-local dir-locals-project-format-style style)
  (dir-locals-project--set 'dir-locals-project-format-style style))

(defun dir-locals-project-toggle-whitespace ()
  "Toggle whitespace cleanup and highlighting for this project."
  (interactive)
  (let ((value (not dir-locals-project-whitespace)))
    (setq-local dir-locals-project-whitespace value)
    (dir-locals-project--set 'dir-locals-project-whitespace value)))

(defun dir-locals-project-toggle-lsp ()
  "Toggle language servers for this project."
  (interactive)
  (let ((value (not dir-locals-project-lsp)))
    (setq-local dir-locals-project-lsp value)
    (dir-locals-project--set 'dir-locals-project-lsp value)))

(defun dir-locals-project-edit-file ()
  "Open this project's dir-locals file for editing."
  (interactive)
  (let ((file (dir-locals-project--file)))
    (find-file file)
    (when (zerop (buffer-size))
      (insert (format ";;; %s --- per-project settings -*- lexical-binding: t -*-\n"
                (file-name-nondirectory file))
        ";; Settings understood by dir-locals-init.el:\n"
        ";;   dir-locals-project-formatting   nil to disable format on save\n"
        ";;   dir-locals-project-format-style 'spaces-4, 'tabs, 'project\n"
        ";;   dir-locals-project-whitespace   nil to disable cleanup/highlighting\n"
        ";;   dir-locals-project-lsp          nil to disable language servers\n"
        "\n((nil . ()))\n"))))

(defun dir-locals-project-reset ()
  "Delete this project's dir-locals file and forget its settings."
  (interactive)
  (let ((file (dir-locals-project--file)))
    (if (not (file-exists-p file))
      (message "No %s in this project" (file-name-nondirectory file))
      (when (yes-or-no-p (format "Delete %s? " (abbreviate-file-name file)))
        (delete-file file)
        (message "Deleted %s" (abbreviate-file-name file))))))

(provide 'dir-locals-init)
;;; dir-locals-init.el ends here
