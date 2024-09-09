;; sidebar-init.el
;; sidebar configuration
;; based on https://www.emacswiki.org/emacs/sr-speedbar.el
;; therefore this file specifically is GNU GPLv3

;; requires
(require 'speedbar)
(require 'util-init)

;; settings
(defvar sidebar-width 30
  "width of sidebar")
(defvar sidebar-left-side nil
  "show the sidebar on left side")

;; sidebar
(defconst sidebar-buffer-name "*SPEEDBAR*"
  "speedbar buffer name")
(defvar sidebar-window nil
  "speedbar window")
(defvar sidebar-last-dir nil
  "last dir refreshed in speedbar")

;; toggle
(defun sidebar-toggle ()
  "toggle sidebar"
  (interactive)
  (if (and (buffer-exist-p speedbar-buffer) (window-exist-p sidebar-window)) ;; sidebar visible
    (sidebar-close)
    (sidebar-open)))

;; create new speedbar
(defun sidebar-create-buffer ()
  "create new sidebar buffer"
  (setq speedbar-buffer (get-buffer-create sidebar-buffer-name)
    speedbar-frame (selected-frame)
    dframe-attached-frame (selected-frame)
    speedbar-select-frame-method 'attached
    speedbar-verbosity-level 0
    speedbar-last-selected-file nil))

;; open sidebar
(defun sidebar-open ()
  "create sidebar"
  (let ((current-window (selected-window))) ;; save current widow
    (unless (buffer-exist-p speedbar-buffer)
      ;; speedbar buff does not exist, create it
      (sidebar-create-buffer))
    ;; speedbar buff exists, point to existing window
    (setq sidebar-window
      (split-window
        (frame-root-window)
        (- sidebar-width)
        (if sidebar-left-side 'left 'right)))
    (set-buffer speedbar-buffer)
    (buffer-disable-undo speedbar-buffer) ;; prevent errors
    (speedbar-mode)
    (speedbar-reconfigure-keymaps)
    (speedbar-update-contents)
    (speedbar-set-timer 1)
    (add-hook 'speedbar-timer-hook 'sidebar-refresh)
    ;; set speedbar to sidebar
    (set-window-buffer sidebar-window (get-buffer sidebar-buffer-name))
    (set-window-dedicated-p sidebar-window t)
    (select-window current-window)))

;; close sidebar
(defun sidebar-close ()
  "close sidebar"
  (remove-hook 'speedbar-timer-hook 'sr-speedbar-refresh)
  (let ((current-window (selected-window))) ;; save current window
    (select-window sidebar-window) ;; select sidebar
    (delete-window sidebar-window) ;; delete sidebar
    (when (window-exist-p current-window) ;; switch back to old window
      (select-window current-window)))) ;; remove refresh hook

;; refresh sidebar
(defun sidebar-refresh ()
  "refresh speedbar on directory change"
  (unless (equal default-directory sidebar-last-dir)
    (setq sidebar-last-dir default-directory) ;; upd dir
    (speedbar-refresh)))

(global-set-key (kbd "C-x C-n") 'sidebar-toggle)

;; dont touch this
(provide 'sidebar-init)
