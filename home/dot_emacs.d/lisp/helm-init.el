;; helm-init.el
;; settings related to helm

;; install helm
(require-package 'helm)
(require-package 'helm-descbinds)
(setq-default completion-styles '(flex))

;; replace default dialogues with helm
(global-set-key (kbd "C-h r")     'helm-info-emacs)
(global-set-key (kbd "M-x")       'helm-M-x)
(global-set-key (kbd "C-x b")     'helm-mini)
(global-set-key (kbd "C-x C-b")   'helm-for-files)
(global-set-key (kbd "C-x C-f")   'helm-find-files)
(global-set-key (kbd "C-x C-S-f") 'helm-find)
(global-set-key (kbd "C-h b")     'helm-descbinds)
(global-set-key (kbd "M-y")       'helm-show-kill-ring)
(global-set-key (kbd "C-c <SPC>") 'helm-mark-ring)
(global-set-key (kbd "C-x r b")   'helm-filtered-bookmarks)
(global-set-key (kbd "C-,")       'helm-calcul-expression)
(global-set-key (kbd "C-h i")     'helm-info)
(global-set-key (kbd "C-x C-d")   'helm-browse-project)
(global-set-key (kbd "C-h a")     'helm-apropos)
(global-set-key (kbd "M-g l")     'goto-line)
(global-set-key (kbd "M-g g")     'goto-line)
(global-set-key (kbd "C-x r p")   'helm-projects-history)
(global-set-key (kbd "C-r")       'helm-imenu)
(global-set-key (kbd "C-s")       'helm-occur)

;; helm-recentf
(require 'advice)
(setq-default
  recentf-max-menu-items  25
  recentf-max-saved-items 25)
(advice-add 'recentf-save-list :around  ;; silent recentf saving
  (lambda (orig-fun)
    (let ((save-silently t)) orig-fun)))
(run-at-time nil (eval-when-compile (* 10 60)) 'recentf-save-list) ;; 10 minute autosave
(recentf-mode 1)

;; allow tab completion in helm
(define-key helm-map (kbd "TAB")   #'helm-execute-persistent-action)
(define-key helm-map (kbd "<tab>") #'helm-execute-persistent-action)
(define-key helm-map (kbd "C-z")   #'helm-select-action)

;; fuzzy matching
(setq-default
  helm-M-x-fuzzy-match         t
  helm-buffers-fuzzy-matching  t
  helm-recentf-fuzzy-match     t
  helm-locate-fuzzy-match      nil
  helm-projectile-fuzzy-match  t)
(recentf-mode 1)

;; forbidden directories under find
(dolist (ext
          '(".gvfs" ".dbus/" "dconf/"))
  (add-to-list 'completion-ignored-extensions ext))

;; interaction settings
(setq-default
  helm-allow-mouse                   t
  helm-move-to-line-cycle-in-source  t
  helm-ff-lynx-style-map             t     ;; use arrow keys in find
  helm-input-idle-delay              0.01  ;; no delay
  helm-idle-delay                    0.01) ;; no delay

;; history
(setq helm-M-x-always-save-history t)

;; appearance
(setq-default
  helm-display-header-line                   nil
  helm-autoresize-mode                       t
  helm-autoresize-max-height                 30   ;; in %
  helm-autoresize-min-height                 10)  ;; in %

;; dont touch this
(helm-mode 1)
(provide 'helm-init)
