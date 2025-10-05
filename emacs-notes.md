[Note]: using elgot and dape
Since using eglot and dape, I prefer my vanilla emacs configuration over my doom emacs configuration.

When using lsp-mode and dape, I prefer the doom emacs configuration

# Doom Emacs Features over my Vanilla Emacs

- **Advantage** Doom emacs has better integration for in coding org src code blocks
- emacs-jupyter completion in org-mode might be disabled but not sure
- lsp-mode is integrated but other features that I want from flycheck and apheleia might still be working in lsp-mode
- lsp-mode uses dape instead of dap-mode
- **Disadvantage** org-mode in large files might be slower, so more stuttering while scrolling and typing
- does not show modeline in many minibuffer
- is configured to show minimal org-agenda UI
- **Disadvantage** rainbow delimiters work but smartparens not working in org source code blocks
- apparent stuttering scrolling might just how the scroll jumps from one line to next; might be more favorable to dumb jump since vim related scrolling is not slower than vanilla emacs
- **Advantage** every base configuration has already been provided by doom emacs
- **Important** Might need to reconfigure **smaller portions** of the configuration when needed
- _may_ need to add custom snippets for LaTeX
- I prefer Doom Emacs dashboard over this one's
- **Advantage** corfu and lsp-mode issues _may_ have been fixed
- **Advantage** has an individual org-capture bash script
- **Advantage** treemacs works flawlessly in the sideline
- **Disadvantage** sideline flymake/flycheck overlaps with popon method

# Vanilla Emacs Features over my Doom Emacs

- More minimal than doom emacs
- **Advantage** has no stuttering issues at the moment
- emacs-jupyter causes error for corfu in src code files since emacs-jupyter has its own completion
- shows modeline in org-agenda and probably ibuffer as well
- lsp-mode and dap-mode are used together
- not everything configured like doom emacs
- **Important** Might need to reconfigure **large portions** of the configuration when needed
- I prefer Doom Emacs dashboard over this one's
- **Advantage** rainbow delimiters and bracket highlighting works flawlessly in my vanilla emacs configuration
- **Advantage** can use whatever emacs package I want without extra configuration
- **Disadvantage** corfu and lsp-mode issues may **not** have been fixed [Note]: Need to check doom emacs config for any suggestion
- **Disadvantage** treemacs does not work flawlessly in the sideline, so using neotree instead
- **Advantage** can use sideline flymake/flycheck exclusively
- **Disadvantage** cannot use doom emacs snippets
- **Advantage** has a much better jinx configuration
