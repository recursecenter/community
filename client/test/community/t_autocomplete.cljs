(ns community.t-autocomplete
  (:require [jasmine.core :refer [pending expect to-equal not-to-equal to-throw]]
            [community.autocomplete :as ac])
  (:require-macros [jasmine.core :refer [context test]]))

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
      (expect (ac/-value textarea-middle) (to-equal "FooBar"))
      (expect (ac/-value textarea-front)  (to-equal "FooBar"))
      (expect (ac/-value textarea-back)   (to-equal "FooBar")))

    (test "can set a value"
      (let [t (ac/-set-value textarea-front "BazQux")]
        (expect (ac/-value t) (to-equal "BazQux"))))

    (test "has a cursor position"
      (expect (ac/-cursor-position textarea-middle) (to-equal 3))
      (expect (ac/-cursor-position textarea-front)  (to-equal 0))
      (expect (ac/-cursor-position textarea-back)   (to-equal 6)))

    (test "can set a cursor position"
      (let [t (ac/-set-cursor-position textarea-front 6)]
        (expect (ac/-cursor-position t) (to-equal 6)))))

  (test "requires a cursor position"
    (expect #(mock-textarea "nope") to-throw)))

(context "community.autocomplete"

  (context "starts-with?"

    (test "returns true only if the given string starts with the substring"
      (expect (ac/starts-with? "" "") (to-equal true))
      (expect (ac/starts-with? "foo" "f") (to-equal true))
      (expect (ac/starts-with? "ofoo" "f") (to-equal false))
      (expect (ac/starts-with? "foo" "fooo") (to-equal false))))

  (context "case-insensitive matches with a leading substring"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (test "returns matches in order"
        (expect (ac/case-insensitive-matches "Da" ac-terms {:on :name})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (test "returns an empty sequence if nothing matches"
        (expect (ac/case-insensitive-matches "Foo" ac-terms {:on :name})
                (to-equal [])))

      (test "is case-insensitive"
        (expect (ac/case-insensitive-matches "da" ac-terms {:on :name})
                (to-equal [{:name "Dave"} {:name "David"}])))))

  (context "extracting an autocomplete query substring"

    (test "can extract a query from a textarea given a marker"
      (expect (ac/extract-query (mock-textarea "Hi there @Za|. How are you?")
                                {:marker "@"})
              (to-equal "Za")))

    (test "extracts from the first marker before the cursor"
      (expect (ac/extract-query (mock-textarea "Hi @Dave there @Za|.")
                                {:marker "@"})
              (to-equal "Za")))

    (test "returns the empty string if the cursor is right after the marker"
      (expect (ac/extract-query (mock-textarea "Hi @Dave there @|. How are you?")
                                {:marker "@"})
              (to-equal "")))

    (test "returns nil if there are no markers before the cursor"
      (expect (ac/extract-query (mock-textarea "Hi there | @Dave")
                                {:marker "@"})
              (to-equal nil))))

  (context "autocomplete possibilities from a textarea and a set of terms"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (test "returns possibilities in order"
        (expect (ac/possibilities (mock-textarea "Hi @Da| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (test "is case insensitive"
        (expect (ac/possibilities (mock-textarea "Hi @da| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (test "returns all possibilities if cursor position is right after the marker"
        (expect (ac/possibilities (mock-textarea "Hi @| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal ac-terms)))

      (test "returns nil if there is no marker"
        (expect (ac/possibilities (mock-textarea "Hi | How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal nil)))

      (test "returns an empty sequence if there are no possibilities"
        (expect (ac/possibilities (mock-textarea "Hi @foobar| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [])))))

  (context "inserting an autocomplete result into a textarea"

    (test "inserts the selection and moves the cursor position"
      (expect (ac/insert (mock-textarea "Hi @Za|. How are you?")
                         "Zach Allaun" {:marker "@"})
              (to-equal (mock-textarea "Hi @Zach Allaun |. How are you?")))

      (expect (ac/insert (mock-textarea "Hi @Za|")
                         "Zach Allaun" {:marker "@"})
              (to-equal (mock-textarea "Hi @Zach Allaun |")))

      (expect (ac/insert (mock-textarea "Hi @Foo|")
                         "Zach Allaun" {:marker "@"})
              (to-equal (mock-textarea "Hi @Zach Allaun |"))))))
