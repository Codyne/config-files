(require 'package)
;;(add-to-list 'package-archives' ("melpa-stable" . "http://melpa-stable.milkbox.net/packages/") t)
(add-to-list 'package-archives' ("melpa" . "https://melpa.org/packages/") t)
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-background-color "#161616")
(set-foreground-color "#f2f2f2")
(require 'whitespace)
(setq whitespace-line-column 80) ;; limit line length
(setq whitespace-style '(face lines-tail))
(setq make-backup-files nil) ; stop creating backup~ files
(setq auto-save-default nil) ; stop creating #autosave# files
(add-hook 'prog-mode-hook 'whitespace-mode)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#242424" "#e5786d" "#95e454" "#cae682" "#8ac6f2" "#333366" "#ccaa8f" "#f6f3e8"])
 '(column-number-mode t)
 '(custom-enabled-themes nil)
 '(fringe-mode 0 nil (fringe))
 '(inhibit-startup-screen t)
 '(package-selected-packages (quote (nasm-mode lua-mode racket-mode csharp-mode)))
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(tooltip-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;if you have tuareg and opam installed on
;;(load "$HOME/.opam/4.04.0/share/emacs/site-lisp/tuareg-site-file")
(menu-bar-mode -1)

(setq initial-scratch-message "")

;; Removes *scratch* from buffer after the mode has been set.
(defun remove-scratch-buffer ()
  (if (get-buffer "*scratch*")
      (kill-buffer "*scratch*")))
(add-hook 'after-change-major-mode-hook 'remove-scratch-buffer)

;; Removes *messages* from the buffer.
(setq-default message-log-max nil)
(kill-buffer "*Messages*")

;; Removes *Completions* from buffer after you've opened a file.
(add-hook 'minibuffer-exit-hook
      '(lambda ()
         (let ((buffer "*Completions*"))
           (and (get-buffer buffer)
                (kill-buffer buffer)))))

;; Don't show *Buffer list* when opening multiple files at the same time.
(setq inhibit-startup-buffer-menu t)

;; Show only one active window when opening multiple files at the same time.
(add-hook 'window-setup-hook 'delete-other-windows)

;; No more typing the whole yes or no. Just y or n will do.
(fset 'yes-or-no-p 'y-or-n-p)

(require 'org)
;; Make Org mode work with files ending in .org
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(eval-after-load "org" '(require 'ox-odt nil t))

;;zathura and comptex functions
(defun zath ()
	"Opens the .pdf of the currently open .tex file in zathura"
	(interactive)
	(call-process-shell-command (concat "zathura " (file-name-sans-extension (buffer-file-name)) ".pdf") nil 0)) ;;(async-shell-command (concat "zathura " (file-name-sans-extension (buffer-file-name)) ".pdf"))

(defun comptex ()
	"Compiles the currently open .tex file to .pdf"
	(interactive)
	(shell-command (concat "pdflatex " (buffer-file-name))))

;;keybind to open the .pdf of the currently open .tex file in zathura
(global-set-key (kbd "C-c v") 'zath)
;;keybind to compile .tex file in open buffer to pdf
(global-set-key (kbd "C-c c") 'comptex)



