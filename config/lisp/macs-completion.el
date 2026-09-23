;;; -*- lexical-binding: t; -*-

                                        ; === === === === === === ;
                                        ;     macs completion     ;
                                        ;                         ;
                                        ;    Completion stack,    ;
                                        ;    Keybindings, and     ;
                                        ;    Which-key.           ;
                                        ;                         ;
                                        ; === === === === === === ;


(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles . (partial-completion orderless))))
      completions-detailed t
      enable-recursive-minibuffers t
      minibuffer-prompt-properties '(read-only t cursor-intangible t face minibuffer-prompt))

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
(vertico-mode 1)
(marginalia-mode 1)
(global-corfu-mode 1)

(require 'nerd-icons-completion)
(nerd-icons-completion-mode 1)
(add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)

(require 'cape)
(add-hook 'completion-at-point-functions #'cape-file)
(add-hook 'completion-at-point-functions #'cape-dabbrev)

(global-set-key (kbd "C-s")   #'consult-line)
(global-set-key (kbd "C-x b") #'consult-buffer)
(global-set-key (kbd "C-c s") #'consult-ripgrep)
(global-set-key (kbd "C-c C-f") #'consult-find)
(global-set-key (kbd "C-.")   #'embark-act)
(global-set-key (kbd "C-;")   #'embark-dwim)

(global-set-key (kbd "C-c z")   #'zoxide-find-file)
(global-set-key (kbd "C-c C-z") #'zoxide-travel)

(when (fboundp 'which-key-mode)
  (which-key-mode 1))

(provide 'macs-completion)
