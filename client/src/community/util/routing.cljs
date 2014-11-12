(ns community.util.routing
  (:require [clojure.string :as str]
            [goog.Uri]
            [goog.string]))

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
      (when c
        ;;TODO: coercion/validation?
        [{k c} (assoc-in req [:components] (vec cs))]))))

(extend-protocol IUnparse
  string
  (unparse [s _]
    s)

  Keyword
  (unparse [k params]
    (when (and (contains? params k)
               (k params))
      (k params))))

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

(defn parse-query-params [query-params-str]
  (let [query-data (goog.Uri.QueryData. query-params-str)]
    (zipmap (map keyword (.getKeys query-data))
            (.getValues query-data))))

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
      (loop [route-pieces []
             parsers parsers]
        (if (empty? parsers)
          (str Separator (str/join Separator (map goog.string/urlEncode route-pieces)))
          (let [[p & ps] parsers]
            (when-let [s (unparse p params)]
              (recur (conj route-pieces s) ps)))))))

  IFn
  (-invoke
    [this string-or-route-name]
    (if-not (string? string-or-route-name)
      ;;Generate a string from route name
      (this string-or-route-name {})
      ;;Try matching this route
      (let [[path query-params] (str/split string-or-route-name #"\?")
            components (->> (str/split path (re-pattern Separator))
                            (remove str/blank?)
                            (map goog.string/urlDecode))
            [params {:as req :keys [query-params]}] (parse this {:components components :query-params query-params})]
        ;;Route only matches when all components have been consumed
        (when (empty? (:components req))
          (if query-params
            (assoc params :query-params (parse-query-params query-params))
            params)))))

  (-invoke
    [this route-name params]
    (unparse this (assoc params :route route-name))))

(defn route
  ([bits]
     (route bits bits))
  ([name bits]
     (assert (not (string? name)) "Routes cannot be named with strings; please use a keyword.")
     (Route. name bits)))
