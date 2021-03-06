;;;; src/parachute/parachute-modification.lisp

(in-package #:protest/for-parachute)

(defmethod parachute:format-result
    ((result test-case-result) (type (eql :extensive)))
  (with-slots (test-case-name test-phase id) result
    (let ((prologue (format nil "In test case ~A, phase ~A, step ~A:~%"
                            test-case-name test-phase id)))
      (concatenate 'string prologue (call-next-method)))))

(defvar *printing-protest-report* nil)

(defmethod parachute:eval-in-context :around
    ((report parachute:plain) (result parachute:parent-result))
  (let* ((*printing-protest-report* t)
         (*last-printed-phase* nil))
    (call-next-method)))

(defvar *last-printed-phase*)

(defmethod parachute:report-on :before
    ((result test-case-result) (report parachute:plain))
  (when *printing-protest-report*
    (alexandria:when-let ((phase (test-phase result)))
      (unless (and (boundp '*last-printed-phase*)
                   (eq phase *last-printed-phase*))
        (setf *last-printed-phase* phase)
        (format (parachute:output report)
                "             #~v@{  ~} Phase ~S~%"
                parachute::*level* phase)))
    (format (parachute:output report) "~4D " (id result))))

(defmethod parachute:report-on :before
    ((result parachute:result) (report parachute:plain))
  (format (parachute:output report)
          " ~:[      ~;~:*~6,3f~] ~a~v@{  ~} "
          (parachute:duration result)
          (case (parachute:status result)
            (:passed  #+asdf-unicode "✔" #-asdf-unicode "o")
            (:failed  #+asdf-unicode "✘" #-asdf-unicode "x")
            (:skipped #+asdf-unicode "ー" #-asdf-unicode "-")
            (T        #+asdf-unicode "？" #-asdf-unicode "?"))
          parachute::*level* T))

(defmethod parachute:report-on :around
    ((result parachute:result) (report parachute:plain))
  (when *printing-protest-report*
    (unless (typep result 'test-case-result)
      (format (parachute:output report) "     ")))
  (call-next-method))
