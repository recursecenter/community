(ns jasmine.core)

(def jasmine-it js/it)
(def jasmine-describe js/describe)
(def jasmine-expect js/expect)

(defn to-equal-cljs []
  #js {:compare
       (fn [actual expected]
         (let [pass (= actual expected)]
           #js {:pass pass
                :message (if pass
                           (str "Expected " (prn-str actual) " not to be equal to " (prn-str expected))
                           (str "Expected " (prn-str actual) " to be equal to " (prn-str expected)))}))})

(defn to-pass-cljs-pred []
  #js {:compare
       (fn [actual pred-str pred expected]
         (let [pass (pred actual expected)]
           #js {:pass pass
                :message (str "Expected " (pr-str actual) " to be " pred-str " " (pr-str expected))}))})

(defn check [pred-str pred actual expected]
  (-> (jasmine-expect actual) (.toPassCljsPred pred-str pred expected)))
