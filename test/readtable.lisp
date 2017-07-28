;;;; test/readtable.lisp

(in-package #:cl-protest)

(defun test-step-macro-reader (stream subchar arg)
  (declare (ignore subchar))
  (let ((form (read stream)))
    `(progn
       (assert *current-step* ()
               "The #? macro must be used inside DEFINE-TEST.")
       (assert (find ,arg *current-step-data* :key #'car) ()
               "Step ~D is not defined in the step data." ,arg)
       (setf *current-step* ,arg)
       ,form
       (setf *current-step* ,(+ arg 1/2)))))

(defreadtable cl-protest
  (:merge :standard)
  (:dispatch-macro-char #\# #\? 'test-step-macro-reader))
