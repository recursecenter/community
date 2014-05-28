(ns community.util)

(defmacro p [form]
  `(let [res# ~form]
     (prn res#)
     res#))

(defmacro p-log [form]
  `(let [res# ~form]
     (.log js/console res#)
     res#))

(defmacro <?
  "Like cljs.core.async/<!, except that it throws js/Errors that
  arrive on the channel."
  [form]
  `(community.util/throw-if-err (cljs.core.async/<! ~form)))
