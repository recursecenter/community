(ns community.components.shared
  (:require [community.routes :as routes]
            [om.core :as om]
            [sablono.core :refer-macros [html]]))

(defn page-not-found-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "PageNotFound")

    om/IRender
    (render [this]
      (html [:h1 "Page not found"]))))
