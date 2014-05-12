(ns community.core
  (:require [ajax.core :as ajax]
            [om.core :as om]
            [om.dom :as dom]))

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

(defn *forum [app owner]
  (om/component
    (dom/h1 nil (str "Hello " (:name app)))))

(js/$
  #(om/root (fn [] (om/build *forum))
           {:name "foo"}
           {:target (.getElementById js/document "app")}))
