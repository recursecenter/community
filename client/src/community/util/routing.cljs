(ns community.util.routing
  (:require [clojure.string :as str]))

(def Separator "/")

(defprotocol IParse
  (parse [this tokens]))

(defprotocol IUnparse
  (unparse [this params]))

(extend-protocol IParse
  string
  (parse [s req]
    (let [{[c & cs] :components} req]
      (when (= s c)
        [{} (assoc-in req [:components] (vec cs))])))

  Keyword
  (parse [k req]
    (let [{[c & cs] :components} req]
      ;;TODO: coercion/validation?
      [{k c} (assoc-in req [:components] (vec cs))])))

(extend-protocol IUnparse
  string
  (unparse [s _]
    s)

  Keyword
  (unparse [k params]
    (if (and (contains? params k)
             (k params))
      (k params)
      (throw (js/Error. (str "Missing route parameter " k))))))

(defrecord Routes
  [routes]
  IParse
  (parse [_ req]
    (->> routes
         (map #(parse % req))
         (remove nil?)
         (sort-by (fn [[params req]]
                    (count (:components req))))
         first))

  IUnparse
  (unparse [_ params]
    (->> routes
         (map #(unparse % params))
         (remove nil?)
         first))

  IFn
  (-invoke
    [this string-or-route-name]
    (->> routes
         (map #(% string-or-route-name))
         (remove nil?)
         first))

  (-invoke
    [this string-or-route-name params]
    (->> routes
         (map #(% string-or-route-name params))
         (remove nil?)
         first)))

(defn routes
  [& routes]
  (Routes. routes))

(defrecord Route
  [name parsers]

  IParse
  (parse [_ req]
    (loop [params {:route name}
           parsers parsers
           req req]
      (if-not (empty? parsers)
        (when-let [[parsed-params rest-req] (parse (first parsers) req)]
          (recur (merge params parsed-params)
                 (rest parsers)
                 rest-req))
        [params req])))

  IUnparse
  (unparse [_ params]
    (when (= (:route params) name)
      (loop [route-str ""
             parsers parsers]
        (if (empty? parsers)
          route-str
          (let [[p & ps] parsers]
            (when-let [s (unparse p params)]
              (recur (str route-str Separator s)
                     ps)))))))

  IFn
  (-invoke
    [this string-or-route-name]
    (if-not (string? string-or-route-name)
      ;;Generate a string from route name
      (this string-or-route-name {})
      ;;Try matching this route
      (let [components (->> (str/split string-or-route-name (re-pattern Separator))
                            (remove str/blank?))
            [params req] (parse this {:components components})]
        ;;Route only matches when all components have been consumed
        (when (empty? (:components req))
          params))))

  (-invoke
    [this route-name params]
    (unparse this (assoc params :route route-name))))

(defn route
  ([bits]
     (route bits bits))
  ([name bits]
     (assert (not (string? name)) "Routes cannot be named with strings; please use a keyword.")
     (Route. name bits)))
