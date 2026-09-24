;;; macs-discord.el --- Elcord presence hook - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up elcord if available
;;;.
;;; Code:

;; Opt-in: elcord is only in the closure when macs is built with
;; `discord = true`, so this is a no-op in the default build.

(declare-function elcord-mode "elcord")
(defvar elcord-use-major-mode-as-main-icon)
(defvar elcord--editor-name)
(defvar elcord-client-id)

(when (require 'elcord nil t)
  (setq elcord-use-major-mode-as-main-icon t
        elcord--editor-name "macs"
        elcord-client-id "1552666524630909029")
  (elcord-mode 1))

(provide 'macs-discord)
;;; macs-discord.el ends here
