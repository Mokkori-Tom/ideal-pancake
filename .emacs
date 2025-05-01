(custom-set-variables
;; custom-set-variables was added by Custom.
;; If you edit it by hand, you could mess it up, so be careful.
;; Your init file should contain only one such instance.
;; If there is more than one, they won't work right.
'(current-language-environment "Japanese")
'(custom-enabled-themes '(wombat))
'(display-battery-mode t)
'(display-line-numbers-type 'relative)
'(display-time-mode t)
'(global-display-line-numbers-mode t)
'(line-number-mode nil)
'(package-archives
'(("gnu" . "https://elpa.gnu.org/packages/")
("nongnu" . "https://elpa.nongnu.org/nongnu/")
("melpa" . "https://melpa.org/packages/")))
'(package-selected-packages '(slime sr-speedbar))
'(scroll-bar-mode nil))
;; Context Menus 
(context-menu-mode 1)
;; Window Tab Line
(global-tab-line-mode 1)

(setq inferior-lisp-program "sbcl")