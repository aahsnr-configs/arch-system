;;; packages.el -*- lexical-binding: t; -*-
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Theme & UI
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
(package! rainbow-delimiters)
(package! buffer-terminator)
(package! nerd-icons-ibuffer)
(package! catppuccin-theme)
(package! rainbow-mode)

;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Org & Roam
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━
(package! org-roam-ui)
(package! org-super-agenda)
(package! consult-org-roam)

;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Citations & LaTeX
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━
(package! laas)
(package! org-fragtog)
(package! yasnippet-snippets)

;;; ━━━━━━━━━━━━━━━━━━━━
;;; Version Control
;;; ━━━━━━━━━━━━━━━━━━━━
(package! magit-todos)
(package! git-gutter)
(package! embark-vc)

;;; ━━━━━━━━━━━━━━━━━━━━━━━
;;; Development & System
;;; ━━━━━━━━━━━━━━━━━━━━━━━
(package! sudo-edit)
(package! feature-mode)
(package! evil-textobj-tree-sitter)
(package! dired-open)
(package! dired-ranger)
(package! jinx)
(package! lsp-latex)

;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Unpinned Packages
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
(unpin! consult)
(unpin! consult-dir)
(unpin! embark)
(unpin! embark-consult)
(unpin! corfu)
(unpin! nerd-icons-corfu)
(unpin! nerd-icons-completion)
(unpin! wgrep)
(unpin! corfu-terminal)
(unpin! orderless)
(unpin! cape)
(unpin! marginalia)
(unpin! vertico)
(unpin! yasnippet)
(unpin! yasnippet-capf)
(unpin! consult-yasnippet)
