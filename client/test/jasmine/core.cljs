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

(defn to-equal [value]
  (fn [expectation]
    (.toEqualCljs expectation value)))

(defn not-to-equal [value]
  (fn [expectation]
    (-> expectation .-not (.toEqualCljs value))))

(defn to-throw [expectation]
  (.toThrow expectation))

(defn expect [value condition]
  (condition (jasmine-expect value)))
