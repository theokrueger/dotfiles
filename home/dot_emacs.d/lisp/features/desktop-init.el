;;; desktop-init.el --- backups of state and files -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; backup management
;; https://www.emacswiki.org/emacs/BackupDirectory
(setopt
  backup-by-copying t      ;; don't clobber symlinks
  backup-directory-alist
  `(("." . ,(locate-user-emacs-file "saves/")))
  auto-save-file-name-transforms
  `((".*" ,(locate-user-emacs-file "auto-save/") t))
  lock-file-name-transforms
  `((".*" ,(locate-user-emacs-file "lock/") t))
  delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t)       ;; use versioned backups
(setopt tramp-backup-directory-alist backup-directory-alist)

(dolist (dir '("saves/" "auto-save/" "lock/"))
  (make-directory (locate-user-emacs-file dir) t))

;; recently visited files
;; Enabled here rather than relying on helm, which only turns it on when one
;; of its recentf sources is used for the first time.
(setopt
  recentf-max-menu-items  25
  recentf-max-saved-items 25
  ;; `recentf-exclude' takes regexps or predicate functions; a quoted symbol
  ;; would be funcalled and silently fail.
  recentf-exclude (list "/tmp/" "/ssh:"
                        (regexp-quote
                         (file-name-as-directory package-user-dir))))
(recentf-mode 1)

(provide 'desktop-init)
;;; desktop-init.el ends here
