;;;;;;;;INITIAL SETUP CMDS;;;;;;;;
(require 'package)
(add-to-list 'package-archives' ("melpa" . "https://melpa.org/packages/") t)

(package-initialize)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-background-color "#161616")
(set-foreground-color "#f2f2f2")

(ac-config-default)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;WHITESPACE SETTING;;;;;;;;
(require 'whitespace)
(setq whitespace-line-column 80) ;; limit line length
(setq whitespace-style '(face empty lines-tail trailing))
(global-whitespace-mode t)
(setq column-number-mode t)
(setq-default indent-tabs-mode t)
(setq-default tab-width 4)
(setq-default c-basic-offset 4
	      tab-width 4
	      indent-tabs-mode t)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq inhibit-eol-conversion t)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;EMACS DIFF SETTING;;;;;;;;
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
 '(smerge-lower ((t (:extend t :background "#ddffdd" :foreground "black"))))
 '(smerge-markers ((t (:extend t :background "grey85" :foreground "black"))))
 '(smerge-refined-added ((t (:inherit smerge-refined-change :background "#aaffaa" :foreground "black"))))
 '(smerge-upper ((t (:extend t :background "#ffdddd" :foreground "black")))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;MISC SANE SETTINGS;;;;;;;;
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
  (shell-command (concat "pdflatex " (buffer-file-name))))

(global-set-key (kbd "C-c c") 'comptex)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
