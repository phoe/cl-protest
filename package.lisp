;;;; package.lisp

(defpackage #:cl-protest
  (:shadowing-import-from #:closer-mop
                          #:standard-generic-function
                          #:defmethod
                          #:defgeneric)
  (:use #:cl
        #:alexandria
        #:closer-mop)
  (:export #:define-protocol
           #:define-test-case
           #:*protocols*
           #:*test-cases*))

(defpackage #:cl-protest-web
  (:use #:cl
        #:alexandria
        #:cl-who
        #:ningle
        #:cl-protest))
