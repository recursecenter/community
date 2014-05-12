(ns community.api
  (:require [ajax.core :as ajax]))

(def api-root "/api")

(defn api-path [path]
  (str api-root path))

(defn GET
  "Makes a GET to the Hacker School API with some default options."
  [resource opts-or-handler]
  (let [user-opts (if (map? opts-or-handler)
                    opts-or-handler
                    {:handler handler})
        default-opts {:error-handler prn}]
    (ajax/GET (api-path resource)
              (merge default-opts user-opts))))
