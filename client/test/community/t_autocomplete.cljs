(ns community.t-autocomplete
  (:require [jasmine.core :refer [pending expect to-equal not-to-equal to-throw]]
            [community.autocomplete :as ac])
  (:require-macros [jasmine.core :refer [describe it]]))

(defrecord FakeTextarea [value cursor-position]
  ac/ICursorPosition
  (-cursor-position [_] cursor-position)
  ac/ISetCursorPosition
  (-set-cursor-position [_ pos] (FakeTextarea. value pos))
  ac/IValue
  (-value [_] value)
  ac/ISetValue
  (-set-value [_ v] (FakeTextarea. v cursor-position)))

(defn fake-textarea
  "\"Hi there @Zach| foo bar\"
   =>
   (map->FakeTextarea {:value \"Hi there @Zach foo bar\"
                       :cursor-position 14})"
  [s]
  (let [cursor-position (.indexOf s "|")]
    (assert (not= -1 cursor-position) "FakeTextarea must include a cursor position.")
    (map->FakeTextarea {:value (str (.substring s 0 cursor-position)
                                    (.substring s (inc cursor-position)))
                        :cursor-position cursor-position})))

(describe "FakeTextarea"

  (let [textarea-middle (fake-textarea "Foo|Bar")
        textarea-front  (fake-textarea "|FooBar")
        textarea-back   (fake-textarea "FooBar|")]

    (it "has a value"
      (expect (ac/-value textarea-middle) (to-equal "FooBar"))
      (expect (ac/-value textarea-front)  (to-equal "FooBar"))
      (expect (ac/-value textarea-back)   (to-equal "FooBar")))

    (it "can set a value"
      (let [t (ac/-set-value textarea-front "BazQux")]
        (expect (ac/-value t) (to-equal "BazQux"))))

    (it "has a cursor position"
      (expect (ac/-cursor-position textarea-middle) (to-equal 3))
      (expect (ac/-cursor-position textarea-front)  (to-equal 0))
      (expect (ac/-cursor-position textarea-back)   (to-equal 6)))

    (it "can set a cursor position"
      (let [t (ac/-set-cursor-position textarea-front 6)]
        (expect (ac/-cursor-position t) (to-equal 6)))))

  (it "requires a cursor position"
    (expect #(fake-textarea "nope") to-throw)))

(describe "community.autocomplete"

  (describe "starts-with?"

    (it "returns true only if the given string starts with the substring"
      (expect (ac/starts-with? "" "") (to-equal true))
      (expect (ac/starts-with? "foo" "f") (to-equal true))
      (expect (ac/starts-with? "ofoo" "f") (to-equal false))
      (expect (ac/starts-with? "foo" "fooo") (to-equal false))))

  (describe "case-insensitive matches with a leading substring"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (it "returns matches in order"
        (expect (ac/case-insensitive-matches "Da" ac-terms {:on :name})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (it "returns an empty sequence if nothing matches"
        (expect (ac/case-insensitive-matches "Foo" ac-terms {:on :name})
                (to-equal [])))

      (it "is case-insensitive"
        (expect (ac/case-insensitive-matches "da" ac-terms {:on :name})
                (to-equal [{:name "Dave"} {:name "David"}])))))

  (describe "extracting an autocomplete query substring"

    (it "can extract a query from a textarea given a marker"
      (expect (ac/extract-query (fake-textarea "Hi there @Za|. How are you?")
                                {:marker "@"})
              (to-equal "Za")))

    (it "extracts from the first marker before the cursor"
      (expect (ac/extract-query (fake-textarea "Hi @Dave there @Za|.")
                                {:marker "@"})
              (to-equal "Za")))

    (it "returns the empty string if the cursor is right after the marker"
      (expect (ac/extract-query (fake-textarea "Hi @Dave there @|. How are you?")
                                {:marker "@"})
              (to-equal "")))

    (it "returns nil if there are no markers before the cursor"
      (expect (ac/extract-query (fake-textarea "Hi there | @Dave")
                                {:marker "@"})
              (to-equal nil))))

  (describe "autocomplete possibilities from a textarea and a set of terms"

    (let [ac-terms (for [name ["Dave" "David" "Zach" "Zachary"]]
                     {:name name})]
      (it "returns possibilities in order"
        (expect (ac/possibilities (fake-textarea "Hi @Da| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (it "is case insensitive"
        (expect (ac/possibilities (fake-textarea "Hi @da| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [{:name "Dave"} {:name "David"}])))

      (it "returns all possibilities if cursor position is right after the marker"
        (expect (ac/possibilities (fake-textarea "Hi @| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal ac-terms)))

      (it "returns nil if there is no marker"
        (expect (ac/possibilities (fake-textarea "Hi | How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal nil)))

      (it "returns an empty sequence if there are no possibilities"
        (expect (ac/possibilities (fake-textarea "Hi @foobar| How are you?")
                                  ac-terms
                                  {:on :name :marker "@"})
                (to-equal [])))))

  (describe "inserting an autocomplete result into a textarea"

    (it "inserts the selection and moves the cursor position"
      (expect (ac/insert (fake-textarea "Hi @Za|. How are you?")
                         "Zach Allaun" {:marker "@"})
              (to-equal (fake-textarea "Hi @Zach Allaun |. How are you?")))

      (expect (ac/insert (fake-textarea "Hi @Za|")
                         "Zach Allaun" {:marker "@"})
              (to-equal (fake-textarea "Hi @Zach Allaun |")))

      (expect (ac/insert (fake-textarea "Hi @Foo|")
                         "Zach Allaun" {:marker "@"})
              (to-equal (fake-textarea "Hi @Zach Allaun |"))))))
