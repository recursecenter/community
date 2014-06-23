(ns community.util.t-routing
  (:require [community.util.routing :as routing]
            [jasmine.core :refer [expect to-equal not-to-equal to-throw]])
  (:require-macros [jasmine.core :refer [context test]]))

(context "community.util.routing"

  (context "routing to the root"
    (let [r (routing/route [])]
      (test "can parse the root"
        (expect (r "/") (to-equal {:route []}))
        (expect (r "")  (to-equal {:route []})))
      (test "can unparse the root"
        (expect (r []) (to-equal "/")))))

  (context "an unnamed route"
    (let [a-b-c ["a" "b" "c"]
          r (routing/route a-b-c)]
      (test "can parse"
        (expect (r "a/b/c") (to-equal {:route a-b-c}))
        (expect (r "/a/b/c") (to-equal {:route a-b-c}))
        (expect (r "/a/b/c/") (to-equal {:route a-b-c}))
        (expect (r "/a/b/c/d") (to-equal nil)))
      (test "can unparse"
        (expect (r a-b-c) (to-equal "/a/b/c")))))

  (context "a named route"
    (let [r (routing/route :abc ["a" "b" "c"])]
      (test "can parse"
        (expect (r "/a/b/c") (to-equal {:route :abc})))
      (test "can unparse"
        (expect (r :abc) (to-equal "/a/b/c")))))

  (context "a route wtesth wildcards"
    (let [r (routing/route :user ["users" :id])]
      (test "can parse"
        (expect (r "/users/10") (to-equal {:route :user :id "10"}))
        (expect (r "/users") (to-equal nil))
        (expect (r "/users/10/foo") (to-equal nil)))
      (test "can unparse"
        (expect (r :user {:id 10}) (to-equal "/users/10"))
        (expect #(r :user {}) to-throw))))

  (context "a suite of routes"
    (let [r (routing/routes
             (routing/route :users ["users"])
             (routing/route :user ["users" :id])
             (routing/route :thread ["thread" :id])
             (routing/route :foobarbaz ["foo" "bar" "baz"]))]
      (test "can parse"
        (expect (r "/foo/bar/baz") (to-equal {:route :foobarbaz}))
        (expect (r "/users/10") (to-equal {:route :user :id "10"}))
        (expect (r "/users") (to-equal {:route :users}))
        (expect (r "/thread/whatever") (to-equal {:route :thread :id "whatever"}))
        (expect (r "/does/not/exist") (to-equal nil)))
      (test "can unparse"
        (expect (r :user {:id 10}) (to-equal "/users/10"))
        (expect (r :users) (to-equal "/users"))
        (expect (r :foobarbaz) (to-equal "/foo/bar/baz"))
        (expect (r :does-not-exist) (to-equal nil))))))
