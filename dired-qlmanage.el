(eval-after-load "dired" '(progn
  (define-key dired-mode-map (kbd "SPC") 'dired-qlmanage)
  (define-key dired-mode-map [up] 'my-dired-previous-line)
  (define-key dired-mode-map [down] 'my-dired-next-line) ))

(require 'dired)
(require 'cl)

;; http://stackoverflow.com/questions/20023458/how-to-delete-process-with-similar-name-one-at-a-time-from-newest-to-oldest
(defun dired-kill-last-process-named (name)
"Function initially written by @wvxvw, and revised by @lawlist."
  (let (p)
    (cl-loop with name-re =
             (format "^%s\\(?:<\\([[:digit:]]+\\)>\\)?" (regexp-quote name))
     for process in (process-list)
     for pname = (process-name process)
     if (string-match name-re pname)
     collect (cons (string-to-number (or (match-string 1 pname) "0")) process)
     into processes
     finally
      (let ((process (cdar (cl-sort processes '> :key 'car))))
        (when (and process (get-process process))
          (delete-process process)
          (setq p process)))) p))

(defvar dired-spawn nil)
(make-variable-buffer-local 'dired-spawn)

(defun dired-qlmanage ()
(interactive)
  (unless (dired-kill-last-process-named "qlmanage")
    (let* ((filename (dired-get-file-for-visit)))
      (set-process-sentinel
        (start-process "qlmanage" nil "/usr/bin/qlmanage" "-p" filename)
        (lambda (p e)
          (setq e (replace-regexp-in-string "\n$" "" e))
          (cond
            ((and (null dired-spawn) (= 9 (process-exit-status p)))
              (message "OFF: dired-qlmanage (%s) | %s | %s" (process-exit-status p) p e))
            ((and dired-spawn (= 9 (process-exit-status p)))
              (message "OFF/ON: dired-qlmanage (%s) | %s | %s" (process-exit-status p) p e)
              (dired-kill-spawn))
            ((= 0 (process-exit-status p))
              (message "OFF (mouse clicked): dired-qlmanage (%s) | %s | %s" (process-exit-status p) p e))
            (t
              (message "ABNORMAL: dired-qlmanage (%s) | %s | %s" (process-exit-status p) p e))))))))

(defun dired-kill-spawn ()
"This is essentially a three level incursion, starting with `dired-qlmanage' and then
calling `dired-kill-spawn' twice."
(interactive)
  (let* ((filename (dired-get-file-for-visit)))
    (set-process-sentinel
      (start-process "qlmanage" nil "/usr/bin/qlmanage" "-p" filename)
      (lambda (p e)
        (setq e (replace-regexp-in-string "\n$" "" e))
        (cond
          ((and (null dired-spawn) (= 9 (process-exit-status p)))
            (message "OFF: dired-kill-spawn (%s) | %s | %s" (process-exit-status p) p e))
          ((and dired-spawn (= 9 (process-exit-status p)))
            (message "OFF/ON: dired-kill-spawn (%s) | %s | %s" (process-exit-status p) p e)
            (dired-kill-spawn))
          ((= 0 (process-exit-status p))
            (message "OFF (mouse clicked): dired-kill-spawn (%s) | %s | %s" (process-exit-status p) p e))
          (t
            (message "ABNORMAL: dired-kill-spawn (%s) | %s | %s" (process-exit-status p) p e)))))))

(defun my-dired-next-line ()
(interactive "^")
  (let ((dired-spawn t))
    (dired-next-line 1)
    (dired-kill-last-process-named "qlmanage")))

(defun my-dired-previous-line ()
(interactive "^")
  (let ((dired-spawn t))
    (dired-previous-line 1)
    (dired-kill-last-process-named "qlmanage")))

(provide 'dired-qlmanage)