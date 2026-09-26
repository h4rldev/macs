;;; macs-explorer.el --- Treemacs setup. - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up treemac's defaults,
;;; and enables a few features.
;;;
;;; Code:

(require 'treemacs)
(require 'treemacs-nerd-icons)

(setq treemacs-width 30
      treemacs-position 'left
      treemacs-select-when-already-in-treemacs 'stay)

(with-eval-after-load 'treemacs
  (treemacs-follow-mode 1)
  (require 'treemacs-nerd-icons)
  (treemacs-nerd-icons-config))

(global-set-key (kbd "C-c e") #'treemacs)
(global-set-key (kbd "C-S-e")   #'treemacs-select-window)

(add-hook 'treemacs-post-buffer-init-hook
          (lambda () (display-line-numbers-mode -1)))

(provide 'macs-explorer)
;;; macs-explorer.el ends here
