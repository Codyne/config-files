;;; init.el --- Full IDE-like Emacs configuration

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Package setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'package)

(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("nongnu". "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(package-initialize)
;; (package-refresh-contents)

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General UI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(global-display-line-numbers-mode 1)
(column-number-mode 1)

(show-paren-mode 1)
(electric-pair-mode 1)

(setq inhibit-startup-screen t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Theme - Tokyo Night
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package tokyo-night
  :ensure t
  :config
  (load-theme 'tokyo-night t))

;; Font
(set-face-attribute 'default nil :font "JetBrainsMono Nerd Font" :height 110)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minibuffer completion (Vertico stack)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-count 12)
  (vertico-cycle t))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  :bind
  ("M-s M-g" . consult-grep)
  ("M-s M-f" . consult-find)
  ("M-s M-r" . consult-ripgrep)
  ("M-s M-b" . consult-buffer)
  ("M-s M-o" . consult-outline)
  ("M-s M-i" . consult-imenu)
  ("M-s M-t" . consult-file-externally))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inline completion (Corfu)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 1)
  (corfu-cycle t)
  (corfu-preview-current t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;; Integration between Corfu and LSP
(use-package corfu-terminal
  :if (not (display-graphic-p))
  :config
  (corfu-terminal-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tree-sitter (syntax highlighting & structural navigation)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package treesit-auto
  :custom
  (treesit-auto-install t)
  :config
  (setq treesit-auto-langs
        (append treesit-auto-langs '(c cpp css html java javascript kotlin python rust bash php dart json toml yaml typescript)))
  (global-treesit-auto-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LSP Mode (IDE features for all languages)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Language server configurations
;; To install missing servers, use M-x lsp-install-server or:
;;   C/C++:   clangd        (already installed system-wide)
;;   Rust:    rust-analyzer (install via rustup: rustup component add rust-analyzer)
;;   Python:  pylsp         (pip install python-lsp-server)
;;   JS/TS:   typescript-language-server (npm i -g typescript-language-server)
;;   PHP:     phpactor       (composer global require phpactor/phpactor)
;;   Bash:    bash-language-server (npm i -g bash-language-server)
;;   Kotlin:  kotlin-language-server (installed by install.sh)
;;   Dart:    dart lsp       (comes with Dart SDK)
;;   HTML/CSS: vscode-html-language-server / vscode-css-language-server
;;             (npm i -g vscode-langservers-extracted)

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook
  ((c-mode
    c++-mode
    java-mode
    kotlin-mode
    python-mode
    php-mode
    rust-mode
    js-mode
    js2-mode
    css-mode
    web-mode
    dart-mode
    sh-mode
    go-mode
    toml-mode
    yaml-mode
    json-mode
    typescript-mode)
   . lsp-deferred)
  :custom
  (lsp-headerline-breadcrumb-enable t)
  (lsp-enable-symbol-highlighting t)
  (lsp-enable-on-type-formatting nil)
  (lsp-idle-delay 0.3)
  (lsp-completion-provider :none)
  (lsp-eldoc-render-all t)
  (lsp-eldoc-enable-hover t)
  (lsp-signature-auto-activate t)
  (lsp-modeline-code-actions-enable t)
  (lsp-keep-workspace-alive nil)
  (lsp-enable-folding t)
  (lsp-enable-imenu t)
  :bind
  ("C-c l d" . lsp-find-definition)
  ("C-c l r" . lsp-find-references)
  ("C-c l R" . lsp-rename)
  ("C-c l h" . lsp-describe-thing-at-point)
  ("C-c l a" . lsp-execute-code-action)
  ("C-c l i" . lsp-find-implementation)
  ("C-c l t" . lsp-find-type-definition)
  ("C-c l o" . lsp-organization)
  ("C-c l =" . lsp-format-buffer)
  ("C-c l c" . lsp-describe-session)
  ("C-c l w" . lsp-workspace-folders-add)
  ("C-c l W" . lsp-workspace-folders-remove)
  ("C-c l f" . lsp-workspace-folders-open)
  ("C-c l q" . lsp-workspace-restart)
  ("C-c l l" . lsp)
  ("C-c l x" . lsp-shutdown-workspace)
  :config
  ;; clangd for C/C++
  (setq lsp-clients-clangd-args '("-j=4"
                                  "--background-index"
                                  "--clang-tidy"
                                  "--completion-style=detailed"
                                  "--header-insertion=never"))
  ;; rust-analyzer
  (setq lsp-rust-analyzer-cargo-watch-command "clippy"
        lsp-rust-analyzer-proc-macro-enable t
        lsp-rust-analyzer-completion-add-call-parenthesis t
        lsp-rust-analyzer-completion-add-call-argument-snippets t)
  ;; Python (pylsp)
  (setq lsp-pylsp-plugins-flake8-enabled t
        lsp-pylsp-plugins-black-enabled t
        lsp-pylsp-plugins-pydocstyle-enabled t
        lsp-pylsp-plugins-mccabe-enabled t))

(use-package lsp-ui
  :commands lsp-ui-mode
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-enable t)
  (lsp-ui-doc-show-with-cursor t)
  (lsp-ui-doc-position 'at-point)
  (lsp-ui-doc-max-width 100)
  (lsp-ui-doc-max-height 50)
  (lsp-ui-doc-border (face-foreground 'default))
  (lsp-ui-sideline-enable t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-peek-always-show t))

(use-package lsp-treemacs
  :commands lsp-treemacs-errors-list
  :bind
  ("C-c l e" . lsp-treemacs-errors-list)
  ("C-c l s" . lsp-treemacs-symbols))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Android / Kotlin development
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq android-sdk-path (expand-file-name "~/Android/Sdk"))
(setenv "ANDROID_HOME" android-sdk-path)
(setenv "ANDROID_SDK_ROOT" android-sdk-path)
(add-to-list 'exec-path (concat android-sdk-path "/platform-tools"))
(add-to-list 'exec-path (concat android-sdk-path "/cmdline-tools/latest/bin"))
(add-to-list 'exec-path (expand-file-name "~/.local/bin"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Debugger (DAP mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package dap-mode
  :after lsp-mode
  :config
  (dap-auto-configure-mode)
  ;; Enable gdb/lldb for C/C++
  (require 'dap-gdb-lldb)
  (setq dap-gdb-lldb-debug-program '("/usr/bin/gdb" "-i=mi"))
  :bind
  ("C-c d b" . dap-breakpoint-toggle)
  ("C-c d c" . dap-continue)
  ("C-c d n" . dap-next)
  ("C-c d i" . dap-step-in)
  ("C-c d o" . dap-step-out)
  ("C-c d d" . dap-disconnect))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagnostics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package flycheck
  :init
  (global-flycheck-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rainbow delimiters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package rainbow-mode
  :hook (css-mode html-mode web-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Which-key
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package which-key
  :config
  (which-key-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Snippets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Projects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package projectile
  :bind-keymap ("C-c p" . projectile-command-map)
  :config
  (projectile-mode)
  (setq projectile-project-search-path '("~/projects" "~")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File tree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package treemacs
  :bind
  ("<f12>" . treemacs)
  ("C-c t t" . treemacs)
  ("C-c t p" . treemacs-projectile)
  ("C-c t r" . treemacs-find-file))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package magit
  :bind
  ("C-c m" . magit-status))

(use-package forge
  :after magit)

(use-package magit-todos
  :config
  (magit-todos-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Formatting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package apheleia
  :config
  (apheleia-global-mode +1))

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compilation & Gradle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq compile-command "make -j$(nproc)")
(setq compilation-scroll-output 'first-error)

(use-package gradle-mode
  :hook (java-mode kotlin-mode)
  :bind
  ("C-c g b" . gradle-build)
  ("C-c g r" . gradle-run)
  ("C-c g t" . gradle-test)
  ("C-c g i" . gradle-install)
  ("C-c g e" . gradle-execute))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Better highlighting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

(setq-default fill-column 80)
(global-display-fill-column-indicator-mode 1)

(setq-default indent-tabs-mode t)
(setq-default tab-width 4)
(setq-default standard-indent 4)
(setq-default c-basic-offset 4)
(setq-default js-indent-level 4)
(setq-default css-indent-offset 4)
(setq-default python-indent-offset 4)
(setq-default sh-basic-offset 4)
(setq-default sh-indentation 4)

(use-package dtrt-indent
  :config
  (dtrt-indent-global-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; No backup files, autosave files, or lock files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)
(setq auto-save-list-file-prefix nil)
(setq vc-follow-symlinks t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Language modes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; C / C++
(use-package cc-mode
  :ensure nil)

;; PHP
(use-package php-mode
  :mode "\\.php\\'")

;; JavaScript
(use-package js2-mode
  :mode "\\.js\\'")

;; TypeScript
(use-package typescript-mode
  :mode "\\.ts\\'")

;; CSS
(use-package css-mode
  :ensure nil
  :mode "\\.css\\'")

;; HTML / JSX / TSX / Vue
(use-package web-mode
  :mode ("\\.html?\\'"
         "\\.vue\\'"
         "\\.jsx\\'"
         "\\.tsx\\'")
  :config
  (setq web-mode-enable-current-element-highlight t)
  (setq web-mode-enable-current-column-highlight t))

;; Java
(use-package lsp-java)

;; Kotlin
(use-package kotlin-mode
  :mode "\\.kt\\'")

;; Python
(use-package python-mode)

;; Dart / Flutter
(use-package dart-mode
  :mode "\\.dart\\'")

(use-package flutter)

;; Rust
(use-package rust-mode
  :mode "\\.rs\\'")

(use-package cargo
  :hook (rust-mode . cargo-minor-mode))

;; Shell / Bash
(use-package sh-script
  :ensure nil)

;; TOML
(use-package toml-mode
  :mode "\\.toml\\'")

;; YAML
(use-package yaml-mode
  :mode "\\.ya?ml\\'")

;; JSON
(use-package json-mode
  :mode "\\.json\\'")

;; CMake
(use-package cmake-mode
  :mode "CMakeLists\\.txt\\'")

;; Makefiles
(add-to-list 'auto-mode-alist '("Makefile\\'" . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("\\.mk\\'" . makefile-gmake-mode))

;; Markdown
(use-package markdown-mode
  :mode "\\.md\\'")

;; LaTeX
(use-package tex
  :ensure auctex)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "C-c c") #'compile)
(global-set-key (kbd "C-c k") #'compile)
(global-set-key (kbd "<f5>") #'recompile)
(global-set-key (kbd "M-n") #'flycheck-next-error)
(global-set-key (kbd "M-p") #'flycheck-previous-error)
(global-set-key (kbd "C-c f") #'apheleia-format-buffer)

;; LSP keybindings (C-c l prefix):
;;   d  - find definition
;;   r  - find references
;;   R  - rename
;;   h  - hover documentation
;;   a  - code actions
;;   i  - find implementation
;;   t  - find type definition
;;   =  - format buffer
;;   l  - start LSP
;;   s  - list symbols
;;   e  - list errors
;; DAP keybindings (C-c d prefix):
;;   b  - toggle breakpoint
;;   c  - continue
;;   n  - next
;;   i  - step in
;;   o  - step out
;;   d  - disconnect

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
