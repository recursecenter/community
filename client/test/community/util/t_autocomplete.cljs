(ns community.util.t-autocomplete
  (:require [community.util.autocomplete :as ac])
  (:require-macros [jasmine.core :refer [context test is all-are throws]]))

(defn mock-textarea
  "\"Hi there @Zach| foo bar\"
   =>
   (map->FakeTextarea {:value \"Hi there @Zach foo bar\"
                       :cursor-position 14})"
  [s]
  (let [cursor-position (.indexOf s "|")]
    (assert (not= -1 cursor-position) "FakeTextarea must include a cursor position.")
    (ac/map->MockTextarea {:value (str (.substring s 0 cursor-position)
                                       (.substring s (inc cursor-position)))
                           :cursor-position cursor-position})))

(context "FakeTextarea"

  (let [textarea-middle (mock-textarea "Foo|Bar")
        textarea-front  (mock-textarea "|FooBar")
        textarea-back   (mock-textarea "FooBar|")]

    (test "has a value"
      (all-are =
        (ac/-value textarea-middle) "FooBar"
        (ac/-value textarea-front)  "FooBar"
        (ac/-value textarea-back)   "FooBar"))

    (test "can set a value"
      (let [t (ac/-set-value textarea-front "BazQux")]
        (is = (ac/-value t) "BazQux")))

    (test "has a cursor position"
      (all-are =
        (ac/-cursor-position textarea-middle) 3
        (ac/-cursor-position textarea-front)  0
        (ac/-cursor-position textarea-back)   6))

    (test "can set a cursor position"
      (let [t (ac/-set-cursor-position textarea-front 6)]
        (is = (ac/-cursor-position t) 6))))

  (test "requires a cursor position"
    (throws (mock-textarea "nope"))))

(context "community.util.autocomplete"

  (context "starts-with?"

    (test "returns true only if the given string starts with the substring"
      (all-are =
        (ac/starts-with? "" "")        true
        (ac/starts-with? "foo" "f")    true
        (ac/starts-with? "ofoo" "f")   false
        (ac/starts-with? "foo" "fooo") false)))

  (context "case-insensitive matches with a leading substring"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (test "returns matches in order"
        (is = (ac/case-insensitive-matches "Da" ac-terms {:on :name})
              [{:name "Dave"} {:name "David"}]))

      (test "returns an empty sequence if nothing matches"
        (is = (ac/case-insensitive-matches "Foo" ac-terms {:on :name}) []))

      (test "is case-insensitive"
        (is = (ac/case-insensitive-matches "da" ac-terms {:on :name})
              [{:name "Dave"} {:name "David"}]))))

  (context "extracting an autocomplete query substring"

    (test "can extract a query from a textarea given a marker"
      (is = (ac/extract-query (mock-textarea "Hi there @Za|. How are you?") {:marker "@"})
            "Za"))

    (test "extracts from the first marker before the cursor"
      (is = (ac/extract-query (mock-textarea "Hi @Dave there @Za|.") {:marker "@"})
            "Za"))

    (test "returns the empty string if the cursor is right after the marker"
      (is = (ac/extract-query (mock-textarea "Hi @Dave there @|. How are you?") {:marker "@"})
            ""))

    (test "returns nil if there are no markers before the cursor"
      (is = (ac/extract-query (mock-textarea "Hi there | @Dave") {:marker "@"})
            nil)))

  (context "autocomplete possibilities from a textarea and a set of terms"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (test "returns possibilities in order"
        (is = (ac/possibilities (mock-textarea "Hi @Da| How are you?")
                                ac-terms
                                {:on :name :marker "@"})
              [{:name "Dave"} {:name "David"}]))

      (test "is case insensitive"
        (is = (ac/possibilities (mock-textarea "Hi @da| How are you?")
                                ac-terms
                                {:on :name :marker "@"})
              [{:name "Dave"} {:name "David"}]))

      (test "returns all possibilities if cursor position is right after the marker"
        (is = (ac/possibilities (mock-textarea "Hi @| How are you?")
                                ac-terms
                                {:on :name :marker "@"})
              ac-terms))

      (test "returns nil if there is no marker"
        (is = (ac/possibilities (mock-textarea "Hi | How are you?")
                                ac-terms
                                {:on :name :marker "@"})
              nil))

      (test "returns an empty sequence if there are no possibilities"
        (is = (ac/possibilities (mock-textarea "Hi @foobar| How are you?")
                                ac-terms
                                {:on :name :marker "@"})
              []))))

  (context "inserting an autocomplete result into a textarea"

    (test "inserts the selection and moves the cursor position"
      (all-are =
        (ac/insert (mock-textarea "Hi @Za|. How are you?")
                   "Zach Allaun" {:marker "@"})
        (mock-textarea "Hi @Zach Allaun |. How are you?")

        (ac/insert (mock-textarea "Hi @Za|")
                   "Zach Allaun" {:marker "@"})
        (mock-textarea "Hi @Zach Allaun |")

        (ac/insert (mock-textarea "Hi @Foo|")
                   "Zach Allaun" {:marker "@"})
        (mock-textarea "Hi @Zach Allaun |")))))
