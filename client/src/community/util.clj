(ns community.util)

(defmacro <?
  "Like cljs.core.async/<!, except that it throws js/Errors that
  arrive on the channel."
  [form]
  `(community.util/throw-if-err (cljs.core.async/<! ~form)))
