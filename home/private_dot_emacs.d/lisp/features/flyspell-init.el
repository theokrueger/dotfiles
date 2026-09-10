;;; flyspell-init.el --- spell checking -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package flyspell
  :hook (fundamental-mode . flyspell-mode))

(defun flyspell-add-word-to-dictionary ()
  "Add the word at point to the personal dictionary."
  (interactive)
  (let ((word (thing-at-point 'word t)))
    (unless word
      (user-error "No word at point"))
    ;; ispell-send-string nothing without a live process.
    (unless (and (boundp 'ispell-process) (process-live-p ispell-process))
      (ispell-set-spellchecker-params)
      (ispell-init-process))
    ;; "*" adds the word to the personal dictionary, "#" writes the
    (ispell-send-string (concat "*" word "\n"))
    (ispell-send-string "#\n")
    (setq ispell-pdict-modified-p '(t))
    ;; recheck the word so its overlay is removed.
    (when (fboundp 'flyspell-word)
      (flyspell-word))
    (message "Added %S to the dictionary" word)))

(global-set-key (kbd "M-.") 'flyspell-add-word-to-dictionary)
(global-set-key (kbd "C-.") 'flyspell-correct-word)

(provide 'flyspell-init)
;;; flyspell-init.el ends here
