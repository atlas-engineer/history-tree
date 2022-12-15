;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(defsystem "history-tree"
  :version "0.0.0"
  :description "Store the history of a browser's visited paths."
  :author "Atlas Engineer LLC"
  :homepage "https://github.com/atlas-engineer/history-tree"
  :license "BSD 3-Clause"
  :in-order-to ((test-op (test-op "history-tree/tests")))
  :depends-on (alexandria
               cl-custom-hash-table
               local-time
               hu.dwim.defclass-star
               trivial-package-local-nicknames)
  :components ((:file "package")
               (:file "history-tree")))

(defsystem "history-tree/submodules"
  :defsystem-depends-on ("nasdf")
  :class :nasdf-submodule-system)

(defsystem "history-tree/tests"
  :defsystem-depends-on ("nasdf")
  :class :nasdf-test-system
  :depends-on (history-tree)
  :targets (:package :history-tree/tests)
  :components ((:file "tests/package")
               (:file "tests/tests")))
