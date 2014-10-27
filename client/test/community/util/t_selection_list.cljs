(ns community.util.t-selection-list
  (:require [community.util.selection-list :as sl]
            [jasmine.core])
  (:require-macros [jasmine.core :refer [context test is all-are]]))

(context "community.util.selection-list"

  (test "seq of an empty selection-list is nil"
    (is = (seq (sl/selection-list [])) nil))

  (let [selection-list (sl/selection-list ["foo" "bar" "baz"])]
    (test "can seq-ify a selection-list"
      (is = (seq selection-list)
            [{:selected? true :value "foo"}
             {:selected? false :value "bar"}
             {:selected? false :value "baz"}]))

    (test "can select :next and :prev"
      (all-are =
        (seq (sl/select :next selection-list))
        [{:selected? false :value "foo"}
         {:selected? true :value "bar"}
         {:selected? false :value "baz"}]

        (seq (sl/select :prev selection-list))
        [{:selected? false :value "foo"}
         {:selected? false :value "bar"}
         {:selected? true :value "baz"}]

        (seq (sl/select :next (sl/select :next (sl/select :next selection-list))))
        [{:selected? true :value "foo"}
         {:selected? false :value "bar"}
         {:selected? false :value "baz"}]))

    (test "can get selected element"
      (is = (sl/selected selection-list) "foo"))))
