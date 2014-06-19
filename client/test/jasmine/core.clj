(ns jasmine.core)

(defn ^:private assert-string-description [val caller-name]
  (assert (string? val)
          (str caller-name
               " requries a string literal description as the first argument")))

(defmacro describe [description & expectations]
  (assert-string-description description "jasmine.core/describe")
  `(jasmine.core/jasmine-describe ~description
     (fn [] ~@expectations)))

(defmacro it
  "(it \"can be sync\"
     (expect 1 (to-equal 1)))
   (it \"can be async\" [done]
     (js/setTimeout (fn [] (expect 1 (to-equal 1)) (done)) 1000))"
  [description & expectations]
  (assert-string-description description "jasmine.core/it")
  (let [[fn-binding expectations] (if (and (vector? (first expectations))
                                           (= 1 (count (first expectations))))
                                    [[(ffirst expectations)] (rest expectations)]
                                    [[] expectations])]
    `(jasmine.core/jasmine-it ~description
       (fn ~fn-binding
         (.addMatchers js/jasmine (cljs.core/js-obj "toEqualCljs" jasmine.core/to-equal-cljs))
                                ~@expectations))))
