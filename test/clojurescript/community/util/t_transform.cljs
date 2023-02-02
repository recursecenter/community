(ns community.util.t-transform
  (:require [community.util.transform :as t :refer-macros [deftransformer deftransform]]
            [jasmine.core])
  (:require-macros [jasmine.core :refer [context test is all-are throws]]))

(context "community.util.transform"

  (context "simple data transforms"

    (test "with no applicable transformers"
      (is = (t/transform {:foo :bar} {}) {:foo :bar})
      (is = (t/transform {:foo :bar} {:baz str}) {:foo :bar}))

    (test "non-nested"
      (is = (t/transform {:n 1} {:n inc}) {:n 2})
      (is = (t/transform {:x 1 :y :foo} {:x inc :y name}) {:x 2 :y "foo"}))

    (test "nested"
      (is = (t/transform {:x {:y 1}} {:y inc}) {:x {:y 2}})
      (is = (t/transform {:x {:y 1}} {:x (constantly :foo)}) {:x :foo})
      (is = (t/transform {:x {:y 1}} {:x #(assoc % :z :zzz) :y inc})
            {:x {:z :zzz :y 2}}))

    (test "will walk vectors"
      (is = (t/transform [{:x 1} {:x 2} {:x 3}] {:x str})
            [{:x "1"} {:x "2"} {:x "3"}])
      (is = (t/transform {:xs [{:x 1} {:x 2} {:x 3}]} {:x str})
            {:xs [{:x "1"} {:x "2"} {:x "3"}]})
      (is = (t/transform {:xs [{:x 1} {:x 2} {:x 3}]} {:xs #(conj % {:x 4}) :x str})
            {:xs [{:x "1"} {:x "2"} {:x "3"} {:x "4"}]})))

  (context "example data transformers"

    (test "can define data transformers and add transforms"
      (deftransformer example)

      (is = (example {:x 1 :y 1}) {:x 1 :y 1})

      (deftransform example {:single :x :many :xs} x
        (inc x))

      (is = (example {:x 1 :y 1}) {:x 2 :y 1})
      (is = (example {:xs [1 2 3] :y 1}) {:xs [2 3 4] :y 1})

      (deftransform example :y y
        (str y))

      (is = (example {:x 1 :y 1}) {:x 2 :y "1"}))

    (test "nested transform"
      (deftransformer api->model)

      (deftransform api->model [:user :mentioned-by]
        {:as user :keys [id first-name last-name]}
        (assoc user
          :id (js/parseInt id)
          :name (str first-name " " last-name)))

      (deftransform api->model {:single :notification, :many :notifications}
        notification
        (update-in notification [:type] keyword))

      (deftransform api->model :thread {:as thread :keys [id]}
        (assoc thread
          :id (js/parseInt id)
          :slug "some-thread-slug"))

      (is =
          (api->model
           {:user
            {:id "123"
             :first-name "Zach"
             :last-name "Allaun"
             :notifications [{:type "mention"
                              :mentioned-by {:id "456"
                                             :first-name "Dave"
                                             :last-name "Albert"}
                              :thread {:id "890"
                                       :title "some cool thread"}}]}})
          {:user
           {:id 123
            :first-name "Zach"
            :last-name "Allaun"
            :name "Zach Allaun"
            :notifications [{:type :mention
                             :mentioned-by {:id 456
                                            :first-name "Dave"
                                            :last-name "Albert"
                                            :name "Dave Albert"}
                             :thread {:id 890
                                      :title "some cool thread"
                                      :slug "some-thread-slug"}}]}}))))
