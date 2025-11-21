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
(when (package! lsp-bridge
        :recipe (:host github
                 :repo "manateelazycat/lsp-bridge"
                 :branch "master"
                 :files ("*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
                 ;; do not perform byte compilation or native compilation for lsp-bridge
                 :build (:not compile)))
  (package! markdown-mode)
  (package! yasnippet))

;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;; Unpinned Packages
;;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━
(unpin! consult)
