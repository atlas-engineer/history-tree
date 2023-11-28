;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(defsystem "history-tree"
  :version "0.1.1"
  :description "Store the history of a browser's visited paths."
  :author "Atlas Engineer LLC"
  :homepage "https://github.com/atlas-engineer/history-tree"
  :license "BSD 3-Clause"
  :depends-on (alexandria
               cl-custom-hash-table
               local-time
               nclasses
               trivial-package-local-nicknames)
  :serial t
  :components ((:file "package")
               (:file "history-tree"))
  :in-order-to ((test-op (test-op "history-tree/tests"))))

(defsystem "history-tree/tests"
  :depends-on ("history-tree" "lisp-unit2")
  :serial t
  :pathname "tests/"
  :components ((:file "package")
               (:file "tests"))
  :perform (test-op (op c)
                    (eval-input
                     "(lisp-unit2:run-tests
                       :package :history-tree/tests
                       :run-contexts #'lisp-unit2:with-summary-context)")))
