;;; undo-tree-init.el --- undo-tree install and settings
;;; Commentary:
;;; Code:

(require-package 'undo-tree)
(require 'undo-tree)

(global-undo-tree-mode)

(setq-default
  undo-tree-visualizer-timestamps nil ;; don't show timestamps in tree
  undo-tree-auto-save-history nil)    ;; disable ~undo-tree~ files

(provide 'undo-tree-init)
;;; undo-tree-init.el ends here
