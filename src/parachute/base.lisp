;;;; src/parachute/base.lisp

(in-package #:protest/for-parachute)

(defvar *define-test-closure-symbol*
  (gensym "PROTEST-CLOSURE-VAR")
  "A symbol used for generating lexical bindings for closures inside
DEFINE-TEST. Must NEVER be proclaimed special.")

(defvar *current-test-case* nil
  "The test case that is currently being executed.")

(defvar *current-test-step* nil
  "The test step that is currently being executed.")

(defclass test-case-result (parachute:value-result)
  ((test-case-name :initarg :test-case-name :accessor test-case-name)
   (id :initarg :id :accessor id)
   (test-phase :initarg :test-phase :accessor test-phase))
  (:default-initargs
   :test-case-name (if *current-test-case* (name *current-test-case*) "????")
   :id (if *current-test-step* (id *current-test-step*) "????")
   :description (if *current-test-step* (description *current-test-step*) nil)
   :test-phase (if *current-test-step* (test-phase *current-test-step*)
                   "????")))

(defclass test-case-comparison-result
    (test-case-result parachute:comparison-result) ())

(defclass test-case-multiple-value-comparison-result
    (test-case-result parachute:multiple-value-comparison-result) ())

(defclass test-case-finishing-result
    (test-case-result parachute:finishing-result) ())

(defun test-step-macro-reader (stream subchar arg)
  (declare (ignore subchar))
  (let ((form (read stream t nil t))
        (symbol *define-test-closure-symbol*))
    `(let* ((*current-test-case* (find-test-case (car ,symbol) (cdr ,symbol)))
            (*current-test-step*
              (when *current-test-case*
                (gethash ,arg (steps *current-test-case*)))))
       ,form)))

(defreadtable protest/parachute
  (:merge :standard)
  (:dispatch-macro-char #\# #\? 'test-step-macro-reader))

(defmacro define-test (name &body arguments-and-body)
  (unless (find-test-case name)
    (protocol-error "Test case named ~S was not found. ~
Use DEFINE-TEST-CASE first." name))
  `(let ((,*define-test-closure-symbol*
           ',(cons name (package-name *package*))))
     (declare (ignorable ,*define-test-closure-symbol*))
     (parachute:define-test ,name ,@arguments-and-body)))
