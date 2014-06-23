(ns community.util.t-selection-list
  (:require [jasmine.core :refer [pending expect to-equal not-to-equal to-throw]]
            [community.util.selection-list :as sl])
  (:require-macros [jasmine.core :refer [context test]]))

(context "community.util.selection-list"

  (test "seq of an empty selection-list is nil"
    (expect (seq (sl/selection-list [])) (to-equal nil)))

  (let [selection-list (sl/selection-list ["foo" "bar" "baz"])]
    (test "can seq-ify a selection-list"
      (expect (seq selection-list)
              (to-equal [{:selected? true :value "foo"}
                         {:selected? false :value "bar"}
                         {:selected? false :value "baz"}])))

    (test "can select :next and :prev"
      (expect (seq (sl/select :next selection-list))
              (to-equal [{:selected? false :value "foo"}
                         {:selected? true :value "bar"}
                         {:selected? false :value "baz"}]))

      (expect (seq (sl/select :prev selection-list))
              (to-equal [{:selected? false :value "foo"}
                         {:selected? false :value "bar"}
                         {:selected? true :value "baz"}]))

      (expect (seq (sl/select :next (sl/select :next (sl/select :next selection-list))))
              (to-equal [{:selected? true :value "foo"}
                         {:selected? false :value "bar"}
                         {:selected? false :value "baz"}])))

    (test "can get selected element"
      (expect (sl/selected selection-list)
              (to-equal "foo")))))
