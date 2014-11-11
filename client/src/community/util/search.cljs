(ns community.util.search
  (:require [community.routes :as routes :refer [routes]]
            [clojure.string :as str]))


(defn search! [query-data]
  (let [filter-str (->> (for [[filter-name value] (:filters query-data)
                              :when value]
                          (str (name filter-name) "=" value))
                        (str/join "&"))
        page-str (str "page=" (:page query-data))
        query-param-str (str (when-not (empty? filter-str) (str filter-str "&")) page-str)]
    (routes/redirect-to (str (routes :search {:query (:text query-data)})
                             "?" query-param-str))))


(defn query [search-text params]
  {:text search-text
   :page (:page params)
   :filters (select-keys params [:author :subforum :thread])})


(defn query-from-text [search-text]
  (query search-text {:page 1}))
