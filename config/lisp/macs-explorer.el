;;; -*- lexical-binding: t; -*-

                                        ; === === === === === === ;
                                        ;      macs explorer      ;
                                        ;                         ;
                                        ;        Treemacs         ;
                                        ;                         ;
                                        ; === === === === === === ;

(setq treemacs-width 30
      treemacs-position 'left
      treemacs-select-when-already-in-treemacs 'stay)

(with-eval-after-load 'treemacs
  (treemacs-follow-mode 1)
  (require 'treemacs-nerd-icons)
  (treemacs-nerd-icons-config))

(global-set-key (kbd "C-c e") #'treemacs)
(global-set-key (kbd "C-c E") #'treemacs-select-window)

(add-hook 'treemacs-post-buffer-init-hook
          (lambda (_) (display-line-numbers-mode -1)))

(provide 'macs-explorer)
