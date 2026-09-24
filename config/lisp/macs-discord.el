;;; macs-discord.el --- Elcord presence hook - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up elcord if available
;;;.
;;; Code:

;; Opt-in: elcord is only in the closure when macs is built with
;; `discord = true`, so this is a no-op in the default build.

(declare-function elcord-mode "elcord")
(defvar elcord-use-major-mode-as-main-icon)
(when (require 'elcord nil t)
  (setq elcord-use-major-mode-as-main-icon t)
  (elcord-mode 1))

(provide 'macs-discord)
;;; macs-discord.el ends here
