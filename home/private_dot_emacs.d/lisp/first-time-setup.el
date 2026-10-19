;;; first-time-setup.el --- settings and configurations that only need to be run during first time setup of .emacs.d -*- lexical-binding: t -*-
;;; Commentary:
;;; Compiles all .el files to .elc and native compiles them as well
;;; Code:

(defun first-time-setup--compile ()
  "Byte-compile every file in `user-emacs-directory', and compile natively."
  (let ((dir user-emacs-directory))
    (byte-recompile-directory dir 0)
    (when (native-comp-available-p)
      (native-compile-async dir 'recursively))))

(let ((fts-file (locate-user-emacs-file "first-setup-ran")))
  (unless (file-exists-p fts-file)
    (message "running first time setup")
    (write-region "" nil fts-file)
    (run-with-idle-timer 1 nil #'first-time-setup--compile)))

(provide 'first-time-setup)
;;; first-time-setup.el ends here
