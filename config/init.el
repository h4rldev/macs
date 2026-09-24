;;; init.el --- The entry-point to the macs config. -*- lexical-binding: t; -*-
;;; Commentary:
;;; Includes all modules exposed by macs,
;;; and runs an idle timer for required modes for start perf.
;;;
;;; Code:

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

(require 'yasnippet)
(require 'envrc)

(require 'macs-ui)
(require 'macs-start)
(require 'macs-completion)
(require 'macs-explorer)
(require 'macs-terminals)
(require 'macs-lsp)
(require 'macs-discord)
(require 'macs-clipboard)
(require 'macs-treesitter)

(run-with-idle-timer
 0.4 nil
 (lambda ()
   (recentf-mode 1)
   (yas-global-mode 1)
   (apheleia-global-mode 1)
   (envrc-global-mode 1)
   (macs-start--recompute-mtimes)))

(provide 'init)
;;; init.el ends here.
