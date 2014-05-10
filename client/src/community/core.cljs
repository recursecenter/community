(ns community.core
  (:require [ajax.core :as ajax]))

(enable-console-print!)

(def api-root "/api")

(defn api-path [path]
  (str api-root path))

(ajax/GET (api-path "/users/me")
          {:handler (fn [res] (println "success!"))
           :error-handler (fn [{:keys [status] :as res}]
                            (if (= status 403)
                              (set! (.-location js/document) "/login")
                              (prn res)))})
