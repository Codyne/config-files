;;;;;;;INITIAL SETUP CMDS;;;;;;;
(require 'package)
(add-to-list 'package-archives' ("melpa" . "https://melpa.org/packages/") t)

(package-initialize)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-background-color "#161616")
(set-foreground-color "#f2f2f2")

(ac-config-default) ;; auto-complete package default
(define-key ac-completing-map [down] nil)
(define-key ac-completing-map [up] nil)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;WHITESPACE SETTING;;;;;;;
(require 'whitespace)
(setq whitespace-line-column 100) ;; limit line length
(setq whitespace-style '(face empty lines-tail trailing))
(global-whitespace-mode t)
(setq column-number-mode t)
;; (setq-default indent-tabs-mode t)
(setq-default tab-width 4)
(setq-default c-basic-offset 4
	      tab-width 4
	      indent-tabs-mode nil)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq inhibit-eol-conversion t)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;EMACS DIFF SETTING;;;;;;;
(defun update-diff-colors ()
  "update the colors for diff faces"
  (set-face-attribute 'diff-added nil
					  :foreground "black" :background "green")
  (set-face-attribute 'diff-removed nil
					  :foreground "black" :background "red")
  (set-face-attribute 'diff-changed nil
					  :foreground "black" :background "purple")
  (set-face-attribute 'diff-header nil
					  :foreground "black" :background "white")
  )
(eval-after-load "diff-mode"
  '(update-diff-colors))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.

 '(background "blue")

 '(font-lock-builtin-face ((((class color) (background dark)) (:foreground "Turquoise"))))
 '(font-lock-comment-face ((t (:foreground "MediumAquamarine"))))
 '(font-lock-constant-face ((((class color) (background dark)) (:bold t :foreground "DarkOrchid"))))
 '(font-lock-doc-string-face ((t (:foreground "green2"))))
 '(font-lock-function-name-face ((t (:foreground "#a16a94"))))
 '(font-lock-keyword-face ((t (:bold t :foreground "#a16a94"))))
 '(font-lock-preprocessor-face ((t (:italic nil :foreground "CornFlowerBlue"))))
 '(font-lock-reference-face ((t (:foreground "DodgerBlue"))))
 '(font-lock-string-face ((t (:foreground "#40a371"))))
 '(font-lock-type-face ((t (:foreground "#E25252"))))
 '(font-lock-variable-name-face ((t (:foreground "#5980E3"))))

 '(whitespace-empty ((t (:foreground "firebrick" :background "gray30"))))

 '(smerge-lower ((t (:extend t :background "#ddffdd" :foreground "black"))))
 '(smerge-markers ((t (:extend t :background "grey85" :foreground "black"))))
 '(smerge-refined-added ((t (:inherit smerge-refined-change :background "#aaffaa" :foreground "black"))))
 '(smerge-upper ((t (:extend t :background "#ffdddd" :foreground "black"))))
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;MISC SANE SETTINGS;;;;;;;
(setq inhibit-startup-buffer-menu t) ; don't show buffer when opening files
(add-hook 'window-setup-hook 'delete-other-windows) ; show only one active win
(fset 'yes-or-no-p 'y-or-n-p) ; only type 'y' or 'n' to confirm yes or no

(if (version<= "26.0.50" emacs-version)
    (global-display-line-numbers-mode) (linum-mode))
(setq linum-format "%4d | ")

(setq lazy-highlight-max-at-a-time nil) ; no max highlight
(setq lazy-highlight-initial-delay 0) ; remove highlight delay
(setq lazy-highlight-cleanup nil) ; keep search strings highlighted
(setq scroll-step 1 scroll-conservatively 10000) ; only scroll 1 line at a time

(set-face-attribute 'region nil :background "#666" :foreground "#ffffff") ; highlight color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;LINUX TABS;;;;;;;;;;;
(defun c-lineup-arglist-tabs-only (ignored)
  "Line up argument lists by tabs, not spaces"
  (let* ((anchor (c-langelem-pos c-syntactic-element))
         (column (c-langelem-2nd-pos c-syntactic-element))
         (offset (- (1+ column) anchor))
         (steps (floor offset c-basic-offset)))
    (* (max steps 1)
       c-basic-offset)))

(add-hook 'c-mode-common-hook
          (lambda ()
            ;; Add kernel style
            (c-add-style
             "linux-tabs-only"
             '("linux" (c-offsets-alist
                        (arglist-cont-nonempty
                         c-lineup-gcc-asm-reg
                         c-lineup-arglist-tabs-only))))))

(add-hook 'c-mode-hook
          (lambda ()
            (let ((filename (buffer-file-name)))
              ;; Enable kernel mode for the appropriate files
              (when (and filename
                         (string-match (expand-file-name "~/src/linux-trees")
                                       filename))
                (setq indent-tabs-mode t)
                (setq show-trailing-whitespace t)
                (c-set-style "linux-tabs-only")))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;STOP START BUFFERS;;;;;;;;
(setq make-backup-files nil) ; stop creating backup~ files
(setq auto-save-default nil) ; stop creating #autosave# files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;KILL EXTRA BUFFERS;;;;;;;;
;; remove scratch buffer
(setq initial-scratch-message "")
(defun remove-scratch-buffer ()
  (if (get-buffer "*scratch*")
      (kill-buffer "*scratch*")))
(add-hook 'after-change-major-mode-hook 'remove-scratch-buffer)

;; remove *messages* buffer
(setq-default message-log-max nil)
(kill-buffer "*Messages*")

;; remove *Completions* buffer after opening a file
(add-hook 'minibuffer-exit-hook
	  '(lambda ()
             (let ((buffer "*Completions*"))
               (and (get-buffer buffer)
                    (kill-buffer buffer)))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;LATEX/ZATHURA BIND;;;;;;;;
;; open the .pdf of the current .tex file in zathura
(defun zath ()
  "Opens the .pdf of the current .tex file in zathura"
  (interactive)
  (call-process-shell-command (concat "zathura "
				      (file-name-sans-extension
				       (buffer-file-name)) ".pdf") nil 0))

(global-set-key (kbd "C-c v") 'zath)

;; compile the current .tex file to .pdf with pdflatex
(defun comptex ()
  "Compiles the current .tex file to .pdf with pdflatex"
  (interactive)
  (shell-command (concat "xelatex " (buffer-file-name) " > /dev/null 2>&1") nil))

(global-set-key (kbd "C-c c") 'comptex)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(color-theme-modern kotlin-mode cmake-mode)))
