;;; -*- lexical-binding: t; -*-

                                        ; === === === === === === ;
                                        ;        macs init        ;
                                        ;                         ;
                                        ;    Entry point, and     ;
                                        ;    Hooks everything.    ;
                                        ;                         ;
                                        ; === === === === === === ;

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

(require 'macs-ui)
(require 'macs-start)
(require 'macs-completion)
(require 'macs-explorer)
(require 'macs-terminals)
(require 'macs-lsp)

(run-with-idle-timer
 0.4 nil
 (lambda ()
   (recentf-mode 1)
   (yas-global-mode 1)
   (apheleia-global-mode 1)
   (envrc-global-mode 1)
   (macs-start--recompute-mtimes)))
