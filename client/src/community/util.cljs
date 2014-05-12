(ns community.util)

(defn throw-if-err
  "Accepts a single value, throwing it if it is a JavaScript Error
  and returning it otherwise."
  [value]
  (if (instance? js/Error value)
    (throw value)
    value))
