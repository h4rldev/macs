;;; early-init.el --- Theme preload. - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Preloads the catppuccin theme
;;; so there's no white flicker on Emacs start.
;;;
;;; Code:

(defvar catppuccin-flavor)
;; Paint the first frame with the real theme so there is no white flash.
;; `load-theme' cannot find the theme this early because
;; `custom-theme-load-path' is not populated yet, so point it at the
;; theme's own directory first.
(let ((theme (locate-library "catppuccin-theme")))
  (when theme
    (add-to-list 'custom-theme-load-path (file-name-directory theme))
    (setq catppuccin-flavor 'mocha)
    (load-theme 'catppuccin t)))

(provide 'early-init)
;;; early-init.el ends here.
