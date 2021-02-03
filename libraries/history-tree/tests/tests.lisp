;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :cl-user)
(uiop:define-package history-tree-tests
  (:use #:common-lisp)
  (:import-from #:class-star #:define-class))
(in-package :history-tree-tests)

(prove:plan nil)

(defun make-tree1 ()
  (let ((tree (htree:make)))
    (dolist (url '(
                   "http://example.root"
                   "http://example.root/A"
                   "http://example.root/A1"))
      (htree:add-child url tree))
    (htree:back tree)
    (htree:add-child "http://example.root/A2" tree)
    (htree:back tree 2)
    (htree:add-child "http://example.root/B" tree)
    (htree:add-child "http://example.root/B1" tree)
    (htree:back tree)
    (htree:add-child "http://example.root/B2" tree)
    tree))

(defun make-tree2 ()
  (let ((tree (htree:make)))
    (htree:add-child "http://example.root" tree)
    (htree:add-child "http://example.root/A" tree)
    (htree:back tree)
    (htree:add-child "http://example.root/B" tree)
    tree))

(prove:subtest "Single entry"
  (let ((history (htree:make))
        (url "http://example.org" ))
    (htree:add-child url history)
    (prove:is (htree:value (htree:current-owner-node history))
              url)))

(prove:subtest "Multiple entry"
  (let ((history (htree:make))
        (url1 "http://example.org")
        (url2 "https://nyxt.atlas.engineer")
        (url3 "http://en.wikipedia.org"))
    (htree:add-child url1 history)
    (htree:add-child url2 history)
    (htree:back history)
    (htree:add-child url3 history)
    (prove:is (htree:value (htree:current-owner-node history))
              url3)
    (prove:is (htree:value (htree:parent (htree:current-owner-node history)))
              url1)
    (htree:back history)
    (htree:go-to-child url2 history)
    (prove:is (htree:value (htree:current-owner-node history))
              url2)))

(prove:subtest "Simple branching tree tests."
  (prove:is (htree:value (htree:current-owner-node (make-tree1)))
            "http://example.root/B2"))

(prove:subtest "History depth."
  (prove:is (htree:depth (make-tree1))
            2))

(prove:subtest "History size."
  (prove:is (htree:size (make-tree1))
            7))

(prove:subtest "All contiguous history nodes for current owner."
  (prove:is (htree:all-contiguous-owned-nodes-data (make-tree1))
            '("http://example.root"
              "http://example.root/B"
              "http://example.root/B2" "http://example.root/B1"
              "http://example.root/A"
              "http://example.root/A2" "http://example.root/A1")))

(prove:subtest "Traverse all history."
  (prove:is (htree:all-contiguous-owned-nodes-data
             (htree:back (make-tree1)))
            '("http://example.root"
              "http://example.root/B"
              "http://example.root/B2" "http://example.root/B1"
              "http://example.root/A"
              "http://example.root/A2" "http://example.root/A1")))

(prove:subtest "Visiting other branches should not reorder the nodes."
  (prove:is (htree:all-contiguous-owned-nodes-data
             (htree:go-to-child
               "http://example.root/A2"
              (htree:go-to-child
               "http://example.root/A"
               (htree:back (make-tree1) 2))))
            '("http://example.root"
              "http://example.root/B"
              "http://example.root/B2" "http://example.root/B1"
              "http://example.root/A"
              "http://example.root/A2" "http://example.root/A1")))

(prove:subtest "Traverse parents."
  (prove:is (htree:all-parents-data
             (htree:back (make-tree1)))
            '("http://example.root")))

(prove:subtest "Traverse forward children."
  (prove:is (htree:all-forward-children-data
             (htree:back (make-tree1)))
            '("http://example.root/B2")))

(prove:subtest "Traverse all children."
  (prove:is (htree:all-children-data
             (htree:back (make-tree1)))
            '("http://example.root/B2" "http://example.root/B1")))

(prove:subtest "Move node to forward-child on add."
  (let ((tree (make-tree2)))
    (prove:is (htree:value (htree:current-owner-node tree))
              "http://example.root/B")
    (htree:back tree)
    (prove:is (htree:value (htree:current-owner-node tree))
              "http://example.root")
    (htree:add-child "http://example.root/A" tree)
    (prove:is (htree:value (htree:current-owner-node tree))
              "http://example.root/A")))

(define-class web-page ()
  ((url "")
   (title ""))
  (:accessor-name-transformer #'class*:name-identity))

(prove:subtest "Compound entry uniqueness"
  (let ((web-page1 (make-instance 'web-page :url "http://example.org"
                                            :title "Example page"))
        (web-page2 (make-instance 'web-page :url "http://example.org"
                                            :title "Same page, another title")))
    (let ((history (htree:make :key #'url)))
      (htree:add-child web-page1 history)
      (htree:add-child web-page2 history)
      (prove:is (hash-table-count (htree:entries history))
                1)
      (prove:is (title (htree:value (htree::first-hash-table-key (htree:entries history))))
                "Same page, another title"))
    (let ((history (htree:make)))
      (htree:add-child web-page1 history)
      (htree:add-child web-page2 history)
      (prove:is (hash-table-count (htree:entries history))
                2)
      (prove:is (sort (loop for key being the hash-keys in (htree:entries history)
                            collect (title (htree:value key)))
                      #'string<)
                (sort (mapcar #'title (list web-page1 web-page2)) #'string<)))))

(prove:subtest "Single owners"
  (let ((history (htree:make))
        (url1 "http://example.org"))
    (htree:add-child url1 history)
    (prove:is (htree:current-owner-identifier history)
              htree::+default-owner+)
    (prove:is (hash-table-count (htree:owners history))
              1)))

(prove:subtest "Multiple owners"
  (let ((history (htree:make :current-owner-identifier "a"))
        (url1 "http://example.org")
        (url2 "https://nyxt.atlas.engineer")
        (url3 "http://en.wikipedia.org"))
    (htree:add-child url1 history)
    (htree:set-current-owner history "b")
    (htree:add-child url2 history)
    (htree:add-child url3 history)
    (prove:is (hash-table-count (htree:entries history))
              3)
    (prove:is (htree:value (htree:current-owner-node history))
              url3)
    (prove:is (htree:value (htree:parent (htree:current-owner-node history)))
              url2)
    (prove:is (htree:parent (htree:parent (htree:current-owner-node history)))
              nil)
    (prove:is (length (htree:nodes (htree:current-owner history)))
              2)
    (prove:is (htree:with-current-owner (history "a")
                (htree:value (htree:current-owner-node history)))
              url1)))

(prove:subtest "Backward and forward"
  (let ((history (htree:make :current-owner-identifier "a"))
        (url1 "http://example.org")
        (url2 "https://nyxt.atlas.engineer")
        (url3 "http://en.wikipedia.org"))
    (htree:add-child url1 history)
    (htree:add-child url2 history)
    (htree:set-current-owner history "b")
    (htree:add-child url3 history :creator-identifier "a")
    (htree:set-current-owner history "a")
    (prove:is (htree:value (htree:current-owner-node history))
              url2)
    (htree:back history)
    (htree:back history)
    (prove:is (htree:value (htree:current-owner-node history))
              url1)
    (htree:forward history)
    (prove:is (htree:value (htree:current-owner-node history))
              url2)
    (htree:forward history)
    (prove:is (htree:value (htree:current-owner-node history))
              url2)))

(prove:subtest "Inter-owner relationships"
  (let ((history (htree:make :current-owner-identifier "a"))
        (url1 "http://example.org")
        (url2 "https://nyxt.atlas.engineer"))
    (htree:add-child url1 history)
    (htree:set-current-owner history "b")
    (htree:add-child url2 history :creator-identifier "a")
    (prove:is (length (htree:nodes (htree:owner history "a")))
              1)
    (prove:is (length (htree:nodes (htree:owner history "b")))
              1)
    (prove:is (htree:parent (htree:current (htree:owner history "b")))
              (htree:current (htree:owner history "a")))))

;; Default owner has its own branch, then we make 2 owners on a 1 separate branch.
;; 1. Remove 1 owner from non-default branch.  Test if all nodes are still there.
;; 2. Remove 2nd owner.  Test if all these nodes got garbage collected, but not
;; the default branch nodes.
(prove:subtest "Owner deletion"
  (let ((tree (htree:make)))
    (dolist (url '("http://example.root"
                   "http://example.root/R"
                   "http://example.root/R1"
                   "http://example.root/R2"))
      (htree:add-child url tree))
    (htree:set-current-owner tree "parent-owner")
    (htree:add-child "http://parent/A" tree)
    (htree:add-child "http://parent/A1" tree)
    (htree:back tree)
    (htree:add-child "http://parent-child/A2" tree)

    (htree:set-current-owner tree "child-owner")
    (htree:add-child "http://child/A3a" tree :creator-identifier "parent-owner")
    (htree:back tree)
    (htree:add-child "http://child/A3b" tree)

    (prove:is (length (htree:nodes (htree:owner tree "parent-owner")))
              3)
    (prove:is (length (htree:all-current-branch-nodes tree))
              5)
    (prove:is (length (htree:nodes (htree:owner tree htree:+default-owner+)))
              4)

    (htree:delete-owner tree "child-owner")

    (prove:isnt (htree:current-owner-identifier tree)
                "child-owner")
    (prove:is (htree:owner tree "child-owner")
              nil)
    (prove:is (length (htree:nodes (htree:owner tree "parent-owner")))
              3)
    (htree:set-current-owner tree "parent-owner")
    (prove:is (length (htree:all-current-branch-nodes tree))
              5)
    (prove:is (length (htree:nodes (htree:owner tree htree:+default-owner+)))
              4)

    (dolist (url-owner (list '("http://parent/A" "parent-owner")
                             '("http://parent/A1" "parent-owner")
                             '("http://parent-child/A2" "parent-owner")
                             '("http://child/A3a" nil)
                             '("http://child/A3b" nil)))
      (prove:is (alexandria:hash-table-keys
                 (htree:bindings (first (htree:find-nodes tree (first url-owner)))))
                (if (second url-owner)
                    (list (htree:owner tree (second url-owner)))
                    nil)))

    (htree:delete-owner tree "parent-owner")
    (prove:is (htree:current-owner-identifier tree)
              htree:+default-owner+)
    (prove:is (htree:owner tree "parent-owner")
              nil)
    (prove:is (hash-table-count (htree:entries tree))
              9)

    (maphash (lambda (entry nodes)
               (prove:is (length nodes)
                         (if (str:contains? "example.root" (htree:value entry))
                             1
                             0)
                         (format nil "~a entry has ~a remaining nodes"
                                 (htree:value entry)
                                 (length nodes))))

             (htree:entries tree))))

(prove:subtest "Visit all nodes until distant node"
  (let* ((history (make-tree1))
         (creator (htree:current-owner-identifier history))
         (distant-node-value "http://example.root/A1")
         (distant-node (first (htree:find-nodes history distant-node-value))))
    (htree:set-current-owner history "b")
    (htree:add-child "b-data" history :creator-identifier creator)

    (htree::visit-all history distant-node)

    (prove:is (htree:value (htree:current-owner-node history))
              distant-node-value)
    (prove:is (sort (mapcar #'htree:value (htree:nodes (htree:owner history "b")))
                    #'string<)
              (sort (copy-seq  '("http://example.root/A1" "http://example.root/A" "http://example.root"
                                 "http://example.root/B" "http://example.root/B2" "b-data"))
                    #'string<))))

(prove:finalize)
