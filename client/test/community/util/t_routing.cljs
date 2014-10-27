(ns community.util.t-routing
  (:require [community.util.routing :as routing]
            [jasmine.core])
  (:require-macros [jasmine.core :refer [context test is all-are throws]]))

(context "community.util.routing"

  (context "routing to the root"
    (let [r (routing/route [])]
      (test "can parse the root"
        (all-are =
          (r "/") {:route []}
          (r "")  {:route []}))
      (test "can unparse the root"
        (is = (r []) "/"))))

  (context "an unnamed route"
    (let [a-b-c ["a" "b" "c"]
          r (routing/route a-b-c)]
      (test "can parse"
        (all-are =
          (r "a/b/c")    {:route a-b-c}
          (r "/a/b/c")   {:route a-b-c}
          (r "/a/b/c/")  {:route a-b-c}
          (r "/a/b/c/d") nil))
      (test "can unparse"
        (is = (r a-b-c) "/a/b/c"))))

  (context "a named route"
    (let [r (routing/route :abc ["a" "b" "c"])]
      (test "can parse"
        (is = (r "/a/b/c") {:route :abc}))
      (test "can unparse"
        (is = (r :abc) "/a/b/c"))))

  (context "a route with wildcards"
    (let [r (routing/route :user ["users" :id])]
      (test "can parse"
        (is = (r "/users/10") {:route :user :id "10"})
        (is = (r "/users") nil)
        (is = (r "/users/10/foo") nil))
      (test "can unparse"
        (is = (r :user {:id 10}) "/users/10")
        (is = (r :user {}) nil))))

  (context "a suite of routes"
    (let [r (routing/routes
             (routing/route :users ["users"])
             (routing/route :user ["users" :id])
             (routing/route :thread ["thread" :id])
             (routing/route :foobarbaz ["foo" "bar" "baz"]))]
      (test "can parse"
        (all-are =
          (r "/foo/bar/baz") {:route :foobarbaz}
          (r "/users/10") {:route :user :id "10"}
          (r "/users") {:route :users}
          (r "/thread/whatever") {:route :thread :id "whatever"}
          (r "/does/not/exist") nil))
      (test "can unparse"
        (all-are =
          (r :user {:id 10}) "/users/10"
          (r :users) "/users"
          (r :foobarbaz) "/foo/bar/baz"
          (r :does-not-exist) nil)))))
