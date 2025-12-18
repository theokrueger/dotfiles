;; first-time-setup.el --- settings and configurations that only need to be run during first time setup of .emacs.d -*- lexical-binding: t -*-
;;; Commentary:
;;; Compiles all .el files to .elc and machine compiles them as well
;;; Code:

(let ((fts-file (expand-file-name "~/.emacs.d/first-setup-ran")))
  (unless (file-exists-p fts-file)
    (message "running first time setup")

    ;; compile all files in config dir
    (byte-recompile-directory (expand-file-name "~/.emacs.d") 0)

    ;; native compile all files in config dir
    (native-compile-async "~/.emacs.d" 'recursively)

    ;; block until native compilation has finished
    (message
      "Awaiting native compilation completion")
    (while comp-files-queue
      (sleep-for 1))
    (message "Native compilation completed")

    ;; mark first time setup as complete
    (write-region "" nil fts-file)))

(provide 'first-time-setup)
;;; first-time-setup.el ends here
