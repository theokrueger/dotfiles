;;; helm-init.el --- settings related to helm
;;; Commentary:
;;; Code:

(require-package 'helm)
(require-package 'helm-descbinds)
(use-package helm
  :demand t
  :config
  (setq-default
    completion-styles '(flex)
    ;; recent saving
    recentf-max-menu-items  25
    recentf-max-saved-items 25
    helm-M-x-always-save-history t
    recentf-exclude '("/tmp/" "/ssh:" 'package-user-dir)
    ;; fuzzy matching
    helm-M-x-fuzzy-match        t
    helm-buffers-fuzzy-matching t
    helm-recentf-fuzzy-match    t
    helm-locate-fuzzy-match     nil
    helm-projectile-fuzzy-match t
    ;; interaction settings
    helm-allow-mouse                   t
    helm-move-to-line-cycle-in-source  t
    helm-ff-lynx-style-map             t     ;; use arrow keys in find
    helm-input-idle-delay              0.01
    helm-idle-delay                    0.01
    ;; appearance
    helm-display-header-line   nil
    helm-autoresize-mode       t
    helm-autoresize-max-height 30 ;; in %
    helm-autoresize-min-heigh  10 ;; in %
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
  ("C-r"       . helm-imenu)
  ("C-s"       . helm-occur)
  ("C-M-s"     . helm-regexp)
  )

(provide 'helm-init)
;;; helm-init.el ends here
