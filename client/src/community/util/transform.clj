(ns community.util.transform
  (:require [community.util :refer [p]]))

(defmacro deftransformer [name]
  `(def ~name (community.util.transform/transformer)))

(defn wrap-vec [value]
  (cond (nil? value) []
        (vector? value) value
        :else [value]))

(defn normalize-key-specs [key-spec]
  (let [key-spec-map (cond (map? key-spec) key-spec
                           (vector? key-spec) {:single key-spec}
                           :else {:single [key-spec]})
        key-spec-map (-> key-spec-map
                         (update-in [:single] wrap-vec)
                         (update-in [:many] wrap-vec))]
    (let [single-key (first (:single key-spec-map))]
      (vec (concat (for [k (:single key-spec-map)]
                     {:key k})
                   (for [k (:many key-spec-map)]
                     {:key k :single-key single-key :many? true}))))))

(defmacro deftransform [name key-spec param-binding & body]
  `(let [handler# (fn [~param-binding] ~@body)]
     ~@(for [{:keys [many? key single-key]} (normalize-key-specs key-spec)]
        (if many?
          `(community.util.transform/-add-transform
            ~name ~key (fn [param#] (mapv #(~name ~single-key %) param#)))
          `(community.util.transform/-add-transform
            ~name ~key (fn [~param-binding] ~@body))))))

;; (defmacro deftransform [name key param-binding & body]
;;   `(community.util.transform/-add-transform ~name ~key
;;      (fn [~param-binding] ~@body)))

;; PROBLEM
;; I'm getting a weird "invalid arity 1" error
;; the commented out version works
