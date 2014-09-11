(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))
  
(defcomponent search [app owner]
  (display-name [_] "Search Box")

  (render [_]
    (html
      [:div "You searched for stuff"])))
