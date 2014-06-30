(ns community.util.transform)

(defmacro deftransformer
  "Defines a top-level transformer called `name`. If you want a
  local/anonymous transformer, use `community.util.transform/transformer`."
  [name]
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

(defmacro deftransform
  "Define a new transform for a given transformer. `key-spec` can have any
  of the following formats:

    :keyword -> will transform values keyed by :keyword
    [:k1 :k2 ...] -> will transform values keyed by :k1, :k2, ...
    {:single :k, :many :ks} -> will transform values keyed by :k, or will
                               map a :k transform over a vector keyed by :ks
    {:single [:k1 :k2 ...], :many [:ks :ys]} -> as above with multiple keys

  `param-binding` can be a symbol or a destructuring form.

  e.g.

    (deftransform my-transformer {:single [:x, :y] :many [:xs :ys]}
      {:keys [a b c]}
      (+ a b c))

    (my-transformer {:x {:a 1 :b 2 :c 3} :ys [{:a 1 :b 1 :c 1}]})
      => {:x 6 :ys [3]}"
  [name key-spec param-binding & body]
  `(let [handler# (fn [~param-binding] ~@body)]
     ~@(for [{:keys [many? key single-key]} (normalize-key-specs key-spec)]
        (if many?
          `(community.util.transform/-add-transform
            ~name ~key (fn [param#] (mapv #(~name ~single-key %) param#)))
          `(community.util.transform/-add-transform
            ~name ~key (fn [~param-binding] ~@body))))))
