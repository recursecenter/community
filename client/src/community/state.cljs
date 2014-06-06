(ns community.state)

(def app-state
  (atom

   {;; route-data will usually contain the currently matched route and
    ;; parsed params, of the form:
    ;;
    ;;   {:route :some-matched-route :param1 :val1 ...}
    ;;
    :route-data nil

    :current-user nil

    :subforum-groups []

    :subforum nil

    :thread nil

    :errors #{}}))

(defn page-state-with-routes [app-state key]
  {key (key app-state)
   :route-data (:route-data app-state)})
