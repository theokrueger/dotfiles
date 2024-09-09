;; first-time-setup.el
;; settings and configurations that only need to be run during first time setup

(let ((fts-file (expand-file-name "~/.emacs.d/elpa/first-setup-ran")))
  (unless (file-exists-p fts-file)
    (message "running first time setup")

    ;; compile all files in config dir
    (byte-recompile-directory (expand-file-name "~/.emacs.d") 0)

    ;; mark first time setup as complete
    (write-region "" nil fts-file)))

;; dont touch this
(provide 'first-time-setup)
