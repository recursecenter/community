(ns community.core
  (:require [community.api :as api]
            [community.models :as models]
            [community.util :as util :refer-macros [<? p]]
            [community.util.routing :as r]
            [om.core :as om]
            [sablono.core :as html :refer-macros [html]]
            [cljs.core.async :as async]
            [goog.window :as window])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(enable-console-print!)

;; TODO
(def app-state
  (atom {:route-data nil
         :current-user nil
         :subforum-groups []
         :subforum nil
         :thread nil}))

(defn page-state-with-routes [app-state key]
  {key (key app-state)
   :route-data (:route-data app-state)})

(def routes
  (r/routes
    (r/route :index [])
    (r/route :subforum ["f" :slug :id])
    (r/route :thread ["t" :slug :id])))

(def pushstate-enabled
  (boolean (.-pushState js/history)))

(defn redirect-to [path]
  (.pushState js/history nil nil path)
  (.dispatchEvent js/window (js/Event. "popstate")))

(defn open-in-new-window? [click-e]
  (or (.-metaKey click-e) (.-ctrlKey click-e)))

(defn link-to [path & body]
  (html
   [:a {:href path
        :onClick (fn [e]
                   (when pushstate-enabled
                     (.preventDefault e)
                     (if (open-in-new-window? e)
                       (window/open path)
                       (redirect-to path))))}
    body]))

(defn set-route! [app]
  (let [route (routes (-> js/document .-location .-pathname))]
    (swap! app assoc :route-data route)))

;; set initial route
(set-route! app-state)

;; TODO:
;; - somehow render different componenets based on the route
;; - set page title
(.addEventListener js/window "popstate" (partial set-route! app-state))


;;; Components
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn post-form-component [_ owner {:keys [on-persisted init-post]}]
  (reify
    om/IDisplayName
    (display-name [_] "PostForm")

    om/IInitState
    (init-state [this]
      {:post init-post
       :c-post (async/chan 1)
       :form-disabled? false})

    om/IWillMount
    (will-mount [this]
      (let [{:keys [c-post post]} (om/get-state owner)]
        (go-loop []
          (when-let [post (<! c-post)]
            (let [new-post (<? (if (:persisted? post)
                                 (api/update-post post)
                                 (api/new-post post)))]
              (om/set-state! owner :form-disabled? false)
              (on-persisted new-post)
              (om/set-state! owner :post (models/empty-post (:thread-id post))))
            ;; TODO: handle invalid posts
            (recur)))))

    om/IWillUnmount
    (will-unmount [this]
      (async/close! (:c-post (om/get-state owner))))

    om/IRender
    (render [this]
      (let [{:keys [form-disabled? c-post post]} (om/get-state owner)]
        (html
         [:form {:onSubmit (fn [e]
                             (.preventDefault e)
                             (when-not form-disabled?
                               (async/put! c-post post)
                               (om/set-state! owner :form-disabled? true)))}
          [:label {:for "post-body"} "Body"]
          [:textarea {:value (:body post)
                      :id "post-body"
                      :name "post[body]"
                      :onChange (fn [e]
                                  (om/set-state! owner [:post :body]
                                                 (-> e .-target .-value)))}]
          [:input {:type "submit"
                   :value (if (:persisted? post) "Update" "Post")
                   :disabled form-disabled?}]])))))

(defn post-component [post owner]
  (reify
    om/IDisplayName
    (display-name [_] "Post")

    om/IInitState
    (init-state [this]
      {:editing? false})

    om/IRenderState
    (render-state [this {:keys [editing?]}]
      (html
       (if editing?
         [:p "editing"]
         #_(om/build post-form-component nil
                   {:opts {:init-post (models/empty-post (:id thread))
                           :on-persisted
                           (fn [post]
                             (om/transact! thread :posts #(conj % post)))}})
         [:li {:key (str "post-" (:id post))}
          [:div (:body post)]
          [:div (:name (:author post))]
          [:a {:href "#"
               :onClick (fn [e]
                          (.preventDefault e)
                          (om/set-state! owner :editing? true))}
           "Edit"]])))))

(defn thread-component [{:keys [route-data thread] :as app} owner]
  (reify
    om/IDisplayName
    (display-name [_] "Thread")

    om/IDidMount
    (did-mount [this]
      (go
        (try
          (let [thread (<? (api/thread (:id @route-data)))]
            (om/update! app :thread thread))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (if (== 404 (:status (ex-data e)))
              (om/update! app [:route-data :route] :page-not-found)
              ;; TODO: generic error component
              (throw e))))))

    om/IRender
    (render [this]
      (html
        (if thread
          [:div
           [:h1 (:title thread)]
           [:ol (om/build-all post-component (:posts thread) {:key :id})]
           (om/build post-form-component nil
                     {:opts {:init-post (models/empty-post (:id thread))
                             :on-persisted
                             (fn [post]
                               (om/transact! thread :posts #(conj % post)))}})]
          [:h1 "Loading..."])))))

(defn new-thread-component [subforum owner]
  (reify
    om/IDisplayName
    (display-name [_] "NewThread")

    om/IInitState
    (init-state [this]
      {:c-draft (async/chan 1)
       :form-disabled? false})

    om/IWillMount
    (will-mount [this]
      (let [{:keys [c-draft]} (om/get-state owner)]
        (go-loop []
          (when-let [draft (<! c-draft)]
            (let [new-thread (<? (api/new-thread (:id @subforum) draft))]
              (redirect-to (routes :thread new-thread)))
            ;; TODO: deal with failing validations (including re-enable the form)
            (recur)))))

    om/IWillUnmount
    (will-unmount [this]
      (async/close! (:c-draft (om/get-state owner))))

    om/IRender
    (render [this]
      (let [{:keys [form-disabled? c-draft]} (om/get-state owner)]
        (html
         [:form {:onSubmit (fn [e]
                             (.preventDefault e)
                             (when-not form-disabled?
                               (async/put! c-draft (:new-thread @subforum))
                               (om/set-state! owner :form-disabled? true)))}
          [:label {:for "thread-title"} "Title"]
          [:input {:type "text"
                   :id "thread-title"
                   :name "thread[title]"
                   :onChange (fn [e]
                               (om/update! subforum [:new-thread :title]
                                           (-> e .-target .-value)))}]
          [:label {:for "thread-body"} "Body"]
          [:textarea {:value (get-in subforum [:new-thread :body])
                      :id "thread-body"
                      :name "thread[body]"
                      :onChange (fn [e]
                                  (om/update! subforum [:new-thread :body]
                                              (-> e .-target .-value)))}]
          [:input {:type "submit"
                   :value "Create thread"
                   :disabled form-disabled?}]])))))

(defn subforum-component [{:keys [route-data subforum] :as app}
                          owner]
  (reify
    om/IDisplayName
    (display-name [_] "Subforum")

    om/IDidMount
    (did-mount [this]
      (go
        (try
          (let [subforum (<? (api/subforum (:id @route-data)))]
            (om/update! app :subforum subforum))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (if (== 404 (:status (ex-data e)))
              (om/update! app [:route-data :route] :page-not-found)
              ;; TODO: generic error component
              (throw e))))))

    om/IRender
    (render [this]
      (html
       (if subforum
         [:div
          [:h1 (:name subforum)]
          [:ol
           (for [{:keys [id slug title created-by]} (:threads subforum)]
             [:li {:key (str "thread-" id)}
              [:h2 (link-to (routes :thread {:id id :slug slug}) title)
               " - "
               created-by]])]
          (om/build new-thread-component subforum)]
         [:h2 "loading..."])))))


(defn subforum-group [{:keys [name subforums id]}]
  (html
   [:li {:key (str "subforum-group-" id)}
    [:h2 name]
    (if (not (empty? subforums))
      [:ol
       (for [{:keys [id slug] :as subforum} subforums]
         [:li {:key (str "subforum-" id)}
          (link-to (routes :subforum {:id id :slug slug})
                   (:name subforum))])])]))

(defn index-component [{:as app :keys [current-user subforum-groups]}
                       owner]
  (reify
    om/IDisplayName
    (display-name [_] "Index")

    om/IDidMount
    (did-mount [this]
      (go
        (om/update! app :subforum-groups (<? (api/subforum-groups)))))

    om/IRender
    (render [this]
      (html
       [:div
        (when (not (empty? subforum-groups))
          [:ol {:id "subforum-groups"}
           (map subforum-group subforum-groups)])]))))

(defn page-not-found-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "PageNotFound")

    om/IRender
    (render [this]
      (html [:h1 "Page not found"]))))


(defn app-component [{:as app :keys [current-user route-data]}
                     owner]
  (reify
    om/IDisplayName
    (display-name [_] "App")

    om/IDidMount
    (did-mount [this]
      (go
        (try
          (let [user (<? (api/current-user))]
            (if (not= user :community.api/no-current-user)
              (om/update! app :current-user user)
              (set! (.-location js/document) "/login")))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (prn (ex-data e))))))

    om/IRender
    (render [this]
      (html
       [:div {:id "app"}
        (if (not current-user)
          [:h1 "Logging in..."]
          [:div
           [:h1 (str "user: " (:first-name current-user))]
           ;; view dispatch
           (condp = (:route route-data)
             :index (om/build index-component app)
             :subforum (om/build subforum-component app)
             :thread (om/build thread-component app)
             ;; this should just be the default case
             :page-not-found (om/build page-not-found-component app))])]))))


(defn ^:export init-app
  "Mounts the om application onto target element."
  [target]
  (om/root app-component app-state {:target target}))
