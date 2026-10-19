;;; helm-init.el --- settings related to helm -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package helm-descbinds
  :commands helm-descbinds)

(use-package helm
  :demand t
  :config
  (setopt
    helm-M-x-always-save-history t
    ;; fuzzy matching
    helm-M-x-fuzzy-match        t
    helm-buffers-fuzzy-matching t
    helm-recentf-fuzzy-match    t
    ;; interaction settings
    helm-allow-mouse                   t
    helm-move-to-line-cycle-in-source  t ;; wrap around at the ends, no ding
    helm-input-idle-delay              0.01
    ;; appearance
    helm-display-header-line   nil
    helm-autoresize-mode       t
    ;; `helm--autoresize-hook' hands both of these to `fit-window-to-buffer',
    ;; which clamps the window height to [min, max]; keeping them equal pins the
    ;; helm window at one height instead of letting it shrink as matches run out.
    helm-autoresize-max-height 50 ;; in %
    helm-autoresize-min-height 50 ;; in %
    helm-M-x-show-short-doc    t
    )

  ;; allow tab completion in helm
  (define-key helm-map (kbd "TAB")   #'helm-execute-persistent-action)
  (define-key helm-map (kbd "<tab>") #'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-z")   #'helm-select-action)

  ;; forbidden directories under find
  (dolist (ext
            '(".gvfs" ".dbus/" "dconf/"))
    (add-to-list 'completion-ignored-extensions ext))

  (helm-mode 1)

  :bind
  ;; replace default dialogues with helm
  ("C-h r"     . helm-info-emacs)
  ("M-x"       . helm-M-x)
  ("C-x b"     . helm-mini)
  ("C-x C-b"   . helm-for-files)
  ("C-x C-f"   . helm-find-files)
  ("C-x C-S-f" . helm-find)
  ("C-h b"     . helm-descbinds)
  ("M-y"       . helm-show-kill-ring)
  ("C-c <SPC>" . helm-mark-ring)
  ("C-x r b"   . helm-filtered-bookmarks)
  ("C-,"       . helm-calcul-expression)
  ("C-h i"     . helm-info)
  ("C-x C-d"   . helm-browse-project)
  ("C-h a"     . helm-apropos)
  ("M-g l"     . goto-line)
  ("M-g g"     . goto-line)
  ("C-x r p"   . helm-projects-history)
  ;; search
  ("C-s"       . helm-occur)
  ("C-r"       . helm-occur)
  ("C-M-s"     . helm-regexp)
  ("C-M-r"     . helm-regexp)
  ("M-g i"     . helm-imenu)
  )

;; move helm keybinds in before the docstring instead of after.
;; yes, this function is is slop.
(defun helm-M-x-transformer-keys-first (candidates)
  "Move the keybinding of each of CANDIDATES in front of its docstring.
CANDIDATES is what `helm-M-x-transformer-1' returns: (DISPLAY . COMMAND)
pairs, where the keybinding is the last character of DISPLAY, carrying it as
a `display' property.  Commands that have no binding, and anything not built
the way `helm-M-x' builds it, are left alone."
  (mapcar
    (lambda (candidate)
      (let ((display (car candidate))
             (name (if (stringp (cdr candidate))
                     (cdr candidate)
                     (format "%s" (cdr candidate)))))
        (if (or (not (stringp display))
              (not (string-prefix-p name display))
              (< (length display) (1+ (length name))))
          candidate
          (let* ((end (1- (length display)))
                  (key (substring display end)))
            (if (not (stringp (get-text-property 0 'display key)))
              candidate
              ;; the character before the key (a space) is dropped along
              ;; with it, and a space is added after the command name.
              (cons (concat (substring display 0 (length name))
                      " " key
                      (substring display (length name) end))
                (cdr candidate)))))))
    candidates))

(with-eval-after-load 'helm-command
  (advice-add 'helm-M-x-transformer-1 :filter-return #'helm-M-x-transformer-keys-first))

(provide 'helm-init)
;;; helm-init.el ends here
