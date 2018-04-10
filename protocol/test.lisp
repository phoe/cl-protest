;;;; protocol/test.lisp

(in-package #:protest/protocol)

;; TODO undoing variables/functions/classes
(defmacro with-test ((success-expected-p) &body body)
  (with-gensyms (function warnp failp)
    (once-only (success-expected-p)
      `(multiple-value-prog1 (values)
         (handler-case
             (let ((*error-output* (make-broadcast-stream))
                   (*protocols* (make-hash-table))
                   (*compile-time-protocols* (make-hash-table)))
               (multiple-value-bind (,function ,warnp ,failp)
                   (compile nil '(lambda () ,@body))
                 (declare (ignore ,warnp))
                 (when (null ,failp)
                   (funcall ,function)
                   (when (not ,success-expected-p)
                     (error "Test failure: unexpected success.")))))
           (protocol-error (e)
             (declare (ignorable e))
             (when ,success-expected-p
               (error "Test failure: unexpected failure of type ~S:~%~A"
                      (type-of e) e))))))))

(defun test-framework-expected-success ()
  (with-test (t)))

(defun test-framework-expected-failure ()
  (with-test (nil) (error 'simple-protocol-error)))

(defun test-framework-unexpected-success ()
  (tagbody (handler-case (progn (with-test (nil)) (go :fail))
             ((and error (not protocol-error)) () (go :ok)))
   :fail (error "fail")
   :ok)
  (values))

(defun test-framework-unexpected-failure ()
  (tagbody (handler-case (with-test (t) (error 'simple-protocol-error))
             ((and error (not protocol-error)) () (go :ok)))
   :fail (error "fail")
   :ok)
  (values))

(defun test-protocol-define-empty ()
  (with-test (t)
    (define-protocol #1=#.(gensym) ())
    (let ((protocol (gethash '#1# *protocols*)))
      (assert (null (description protocol)))
      (assert (null (tags protocol)))
      (assert (null (dependencies protocol)))
      (assert (null (exports protocol)))
      (assert (null (elements protocol))))))

(defun test-protocol-define-detailed ()
  (with-test (t)
    (define-protocol #1=#.(gensym) (:export ()))
    (define-protocol #2=#.(gensym) (:dependencies (#1#)
                                    :tags (#3=#.(gensym))
                                    :description "asdf"
                                    :export t))
    (let ((protocol (gethash '#2# *protocols*)))
      (assert (string= "asdf" (description protocol)))
      (assert (equal '(#3#) (tags protocol)))
      (assert (equal '(#1#) (dependencies protocol)))
      (assert (null (exports protocol)))
      (assert (null (elements protocol))))))

(defun test-protocol-define-dependencies ()
  (with-test (t)
    (define-protocol #1=#.(gensym) ())
    (define-protocol #2=#.(gensym) (:dependencies (#1#)))
    (define-protocol #3=#.(gensym) (:dependencies (#1#)))
    (define-protocol #4=#.(gensym) (:dependencies (#2# #3#)))
    (define-protocol #5=#.(gensym) (:dependencies (#2#)))
    (define-protocol #6=#.(gensym) (:dependencies (#3#)))
    (define-protocol #7=#.(gensym) (:dependencies (#2#)))
    (define-protocol #.(gensym) (:dependencies (#1# #2# #3# #4# #5# #6# #7#)))))

(defun #5=test-protocol-define-circular-dependency ()
  (with-test (nil)
    (define-protocol #1=#.(gensym) ())
    (define-protocol #2=#.(gensym) (:dependencies (#1#)))
    (define-protocol #3=#.(gensym) (:dependencies (#2#)))
    (define-protocol #4=#.(gensym) (:dependencies (#3#)))
    (define-protocol #1# (:dependencies (#4#)))))

(defun #2=test-protocol-define-self-dependency ()
  (with-test (nil)
    (define-protocol #1=#.(gensym) (:dependencies (#1#)))))

(defun #2=test-protocol-define-invalid-name ()
  (with-test (nil) (define-protocol 2 ()))
  (with-test (nil) (define-protocol "PROTOCOL" ()))
  (with-test (nil) (define-protocol '(#.(gensym) #.(gensym)) ()))
  (with-test (nil) (define-protocol nil ())))

(defun #2=test-protocol-define-invalid-dependencies ()
  (with-test (nil) (define-protocol #.(gensym) (:dependencies (2))))
  (with-test (nil) (define-protocol #.(gensym) (:dependencies ("ABC"))))
  (with-test (nil) (define-protocol #.(gensym) (:dependencies ((#.(gensym))))))
  (with-test (nil) (define-protocol #.(gensym) (:dependencies ((1 2 3 4)))))
  (with-test (nil) (define-protocol #.(gensym) (:dependencies (nil)))))

(defun test-protocol-define-duplicate-elements ()
  (with-test (nil) (define-protocol #.(gensym) ()
                     (:variable #1=#.(gensym))
                     (:variable #1#)))
  (with-test (nil) (define-protocol #.(gensym) ()
                     (:config (#2=#.(gensym)))
                     (:config (#2#)))))

(defun test-protocol-define-duplicate-elements-inheritance ()
  (with-test (nil)
    (define-protocol #1=#.(gensym) ()
      (:variable #2=#.(gensym)))
    (define-protocol #.(gensym) (:dependencies (#1#))
      (:variable #2#))))

(defun test-protocol-define-category ()
  (with-test (t)
    (unwind-protect
         (progn (define-protocol #.(gensym) ()
                  (:category #1=(:foo :bar)) #2="qwer")
                (assert (string= #2# (documentation '#1# 'category))))
      (setf (documentation '#1# 'category) nil))))

(defun test-protocol-define-class ()
  (with-test (t)
    (unwind-protect
         (progn (define-protocol #.(gensym) ()
                  (:class #1=#.(gensym) () ())
                  #2="qwer")
                (assert (find-class '#1#))
                (assert (string= #2# (documentation '#1# 'cl:type))))
      (setf (documentation '#1# 'cl:type) nil
            (find-class '#1#) nil))))

(defun test-protocol-define-class-instantiate ()
  (with-test (nil)
    (unwind-protect
         (progn (define-protocol #.(gensym) ()
                  (:class #1=#.(gensym) () ()))
                (make-instance (find-class '#1#)))
      (setf (find-class '#1#) nil))))

(defun test-protocol-define-condition-type ()
  (with-test (t)
    (unwind-protect
         (progn (define-protocol #.(gensym) ()
                  (:condition-type #1=#.(gensym) () ())
                  #2="qwer")
                (assert (find-class '#1#))
                (assert (string= #2# (documentation '#1# 'cl:type))))
      (setf (documentation '#1# 'cl:type) nil
            (find-class '#1#) nil))))

(defun #2=test-protocol-define-condition-type-instantiate ()
  ;; https://bugs.launchpad.net/sbcl/+bug/1761950
  #+sbcl (warn "~A broken on SBCL; skipping.~%" '#2#)
  #-sbcl (with-test (nil)
           (unwind-protect
                (progn (define-protocol #.(gensym) ()
                         (:condition-type #1=#.(gensym) () ()))
                       (make-condition (find-class '#1#)))
             (setf (find-class '#1#) nil))))

(defun test-protocol-define-config ()
  (with-test (t)
    (let* ((variable nil)
           (*configuration-setter*
             (lambda (x y) (declare (ignore x y)) (setf variable t))))
      (unwind-protect
           (progn (define-protocol #.(gensym) ()
                    (:config #1=(:foo :bar) string :mandatory "a")
                    #2="qwer")
                  (assert (string= #2# (documentation '#1# 'config))))
        (setf (documentation '#1# 'config) nil)))))

(defun test-protocol-define-function ()
  (unwind-protect
       (progn (define-protocol #.(gensym) ()
                (:function #1=#.(gensym) (#2=#.(gensym) #3=#.(gensym)) 'string)
                #4="qwer")
              (assert (string= #4# (documentation '#1# 'function))))
    (fmakunbound '#1#)
    (setf (documentation '#1# 'function) nil)))

(defun test-protocol-define-macro ()
  (unwind-protect
       (progn (define-protocol #.(gensym) ()
                (:macro #1=#.(gensym) (#2=#.(gensym) #3=#.(gensym)))
                #4="qwer")
              (assert (string= #4# (documentation '#1# 'function))))
    (fmakunbound '#1#)
    (setf (documentation '#1# 'function) nil)))

(defun test-protocol-define-variable ()
  (warn "Test not implemented yet."))
