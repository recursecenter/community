(ns jasmine.core
  (:refer-clojure :exclude [test]))

(defn ^:private assert-string-description [val caller-name]
  (assert (string? val)
          (str caller-name
               " requries a string literal description as the first argument")))

(defmacro context [description & expectations]
  (assert-string-description description "jasmine.core/context")
  `(jasmine.core/jasmine-describe ~description
     (fn [] ~@expectations)))

(defmacro test
  "(test \"can be sync\"
     (is = 1 1))
   (test \"can be async\" [done]
     (js/setTimeout (fn [] (is = 1 1) (done)) 1000))"
  [description & expectations]
  (assert-string-description description "jasmine.core/test")
  (let [[fn-binding expectations] (if (and (vector? (first expectations))
                                           (= 1 (count (first expectations))))
                                    [[(ffirst expectations)] (rest expectations)]
                                    [[] expectations])]
    `(jasmine.core/jasmine-it ~description
       (fn ~fn-binding
         (.addMatchers js/jasmine (cljs.core/js-obj "toPassCljsPred" jasmine.core/to-pass-cljs-pred))
         ~@expectations))))

(defmacro is [pred actual expected]
  `(jasmine.core/check ~(str pred) ~pred ~actual ~expected))

(defmacro all-are [pred & pairs]
  (let [pairs (partition 2 pairs)]
    `(do ~@(map (fn [[actual expected]] `(is ~pred ~actual ~expected)) pairs))))

(defmacro throws [expr]
  `(-> (jasmine.core/jasmine-expect (fn [] ~expr)) (.toThrow)))
