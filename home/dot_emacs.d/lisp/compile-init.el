;; compile-init.el
;; hooks to compile .el files into bytecode as required.
;; provides a noticeable performance improvement after first setup

;; remove .elc files on visit corresponding .el, and recompile .el files when saving them
;; https://www.emacswiki.org/emacs/AutoRecompile
(defun remove-elc-when-visit ()
  "upon visiting <file>.el, remove corresponding <file>.elc"
  (make-local-variable 'find-file-hook)
  (add-hook 'find-file-hook
    (lambda ()
      (if (file-exists-p (concat buffer-file-name "c"))
        (delete-file (concat buffer-file-name "c"))))))
(add-hook 'emacs-lisp-mode-hook 'remove-elc-when-visit)

(defun byte-compile-when-save()
  "upon saving <file>.el, compile <file.elc>"
  (make-local-variable 'after-save-hook)
  (add-hook 'after-save-hook
    (lambda ()
      (if (buffer-file-name)
	(byte-compile-file buffer-file-name)))))
(add-hook 'emacs-lisp-mode-hook 'byte-compile-when-save)

;; always load .elc
(setq load-prefer-newer nil)

;; do not ask to save for compile command
(setq compilation-ask-about-save nil)

;; dont touch this
(provide 'compile-init)
