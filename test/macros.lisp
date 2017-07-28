;;;; test/macros.lisp

(in-package #:cl-protest)

(defmacro define-test-case
    (&whole whole test-case-name options &body steps)
  (declare (ignore options steps))
  `(let ((data (cdr ',whole))
         (value (find ',test-case-name *test-cases* :key #'car)))
     (unless (equal data value)
       (when value
         (warn "Redefining ~S in DEFINE-TEST-CASE" ',test-case-name))
       (setf *test-cases*
             (cons data
                   (if value
                       (remove ',test-case-name *test-cases* :key #'car)
                       *test-cases*))))))

(defmacro define-test-package (package-designator test-package-designator)
  `(setf (gethash (find-package ,package-designator) *test-packages*)
         (find-package ,test-package-designator)))

(defmacro define-test (test-name &body body)
  (let ((test-case (find test-name *test-cases* :key #'car)))
    (unless test-case
      (error *test-case-not-found* test-name))
    (let ((body (make-test-function test-name body)))
      (multiple-value-bind (package foundp)
          (gethash (symbol-package test-name) *test-packages*)
        (unless foundp
          (error *test-package-not-found* (symbol-package test-name)))
        (let ((symbol (intern (symbol-name test-name) package)))
          (export symbol package)
          `(test ,symbol ,body))))))
