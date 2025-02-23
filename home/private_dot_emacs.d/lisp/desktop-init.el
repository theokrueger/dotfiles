;;; desktop-init.el --- backups of state and files -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; backup management
;; https://www.emacswiki.org/emacs/BackupDirectory
(setq-default
   backup-by-copying t      ;; don't clobber symlinks
   backup-directory-alist
    '(("." . "~/.emacs.d/saves/"))
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t)       ;; use versioned backups

(provide 'desktop-init)
;;; desktop-init.el ends here
