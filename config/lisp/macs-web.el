;;; macs-web.el --- Web templating via web-mode - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Register everything available to fit web-mode.
;;;
;;; Code:

(require 'web-mode)

;; web-mode never registers itself in auto-mode-alist, so claim its whole
;; engine table here. This replaces the tree-sitter HTML path.
(mapc (lambda (re)
        (add-to-list 'auto-mode-alist (cons re #'web-mode)))
      '("\\.html?\\'"
        "\\.svelte\\'"
        "\\.vue\\'"
        "\\.astro\\'"
        "\\.component\\.html\\'"
        "\\.html\\.tpl\\'"
        "\\.\\(erb\\|rhtml\\|erb\\.html\\|ecr\\)\\'"
        "\\.\\(hb\\.html\\|hbs\\)\\'"
        "\\.ejs\\'"
        "\\.mustache\\'"
        "\\.go\\(html\\|tmpl\\)\\'"
        "\\.\\(p[hs]p\\|ctp\\)\\'"
        "\\.blade\\.php\\'"
        "\\.soy\\'"
        "\\.mako?\\'"
        "\\.ftl\\'"
        "\\.\\(jinja\\|nwt\\)\\'"
        "\\.\\(cs\\|vb\\)html\\'"
        "\\.thtml\\'"
        "\\.tpl\\'"
        "\\.tag\\'"
        "\\.v\\(sl\\|tl\\|m\\)\\'"
        "\\.\\(chtml\\|mustache\\)\\'"
        "\\.dust\\'"
        "\\.axvw\\'"
        "\\.anki\\'"
        "\\.hero\\'"
        "\\.marko\\'"
        "\\.mas\\'"
        "\\.epl?\\'"
        "\\.lsp\\'"
        "\\.pml\\'"
        "\\.xoops\\'"
        "\\.ee\\'"
        "\\.clemb\\'"
        "\\.ctml\\'"))

(provide 'macs-web)
;;; macs-web.el ends here.
