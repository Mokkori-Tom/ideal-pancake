; ライブラリごとコピーする
; 例えば
; ./  
; ├── quicklisp/  
; └── write-csv.lisp

; 外部更新を禁止の場合（オフライン前提）
; (setf ql:*update-dist* nil)         
; ローカル quicklisp を使用
(load "./quicklisp/setup.lisp")     
; 必要ライブラリをロード
(ql:quickload :cl-csv)              
; 以降にスクリプトを書く 
 