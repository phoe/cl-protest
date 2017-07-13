;;;; parse-class.lisp

(in-package #:cl-protest)

(defun parse-class (form docstring)
  `(progn
     (verify-class ',(first form) ',(second form)
                   ',(third form) ,docstring)
     (define-protocol-class ,@form)
     ,@(when docstring
         `((setf (documentation ',(first form) 'type)
                 ,(format nil docstring))))))
