(ns community.util.transform)

(defmacro deftransformer [name]
  `(def ~name (community.util.transform/transformer)))

(defmacro deftransform [name key param-binding & body]
  `(community.util.transform/-add-transform ~name ~key
     (fn [~param-binding] ~@body)))
