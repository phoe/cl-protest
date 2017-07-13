;;;; cl-protest-vars.lisp

(in-package #:cl-protest)

(defvar *protocols* '())

(defvar *test-cases* '())

(defparameter *class-mismatch-format*
  "Mismatched class forms for protocol class ~S.
Old documentation: ~S
New documentation: ~S
Old superclasses: ~S
New superclasses: ~S
Old slot names: ~S
New slot names: ~S")
