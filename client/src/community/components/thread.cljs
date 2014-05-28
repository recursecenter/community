(ns community.components.thread
  (:require [community.util :refer-macros [<? p]]
            [community.api :as api]
            [community.models :as models]
            [community.partials :as partials]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [om.core :as om]
            [sablono.core :refer-macros [html]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defn post-form-component [_ owner {:keys [after-persisted init-post]}]
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
      (let [{:keys [c-post]} (om/get-state owner)]
        (go-loop []
          (when-let [post (<! c-post)]
            (let [new-post (<? (if (:persisted? post)
                                 (api/update-post post)
                                 (api/new-post post)))]
              (om/set-state! owner :form-disabled? false)
              (after-persisted new-post
                               #(om/set-state! owner :post (models/empty-post (:thread-id new-post)))))
            ;; TODO: handle invalid posts
            (recur)))))

    om/IWillUnmount
    (will-unmount [this]
      (async/close! (:c-post (om/get-state owner))))

    om/IRender
    (render [this]
      (let [{:keys [form-disabled? c-post post]} (om/get-state owner)]
        (html
          [:div.panel.panel-default
           [:div.panel-body
            [:form {:onSubmit (fn [e]
                                (.preventDefault e)
                                (when-not form-disabled?
                                  (async/put! c-post post)
                                  (om/set-state! owner :form-disabled? true)))}
             [:div.form-group
              (let [post-body-id (str "post-body-" (:id post))]
                [:label {:for post-body-id} "Body"]
                (om/build shared/resizing-textarea-component nil
                  {:opts {:id post-body-id
                          :class "form-control"
                          :value (:body post)
                          :name "post[body]"
                          :onChange (fn [e]
                                      (om/set-state! owner [:post :body]
                                                     (-> e .-target .-value)))}}))]
             [:button.btn.btn-default {:type "submit"
                                       :disabled form-disabled?}
              (if (:persisted? post) "Update" "Post")]]]])))))

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
       [:li.post {:key (:id post)}
        [:div.row
         [:div.post-author
          [:img.post-profile-image
           {:src (-> post :author :avatar-url)
            :width "50"       ;TODO: request different image sizes
            }]
          [:a {:href (routes/hs-route :person (:author post))}
           (-> post :author :name)]]
         [:div.post-body
          (if editing?
            (om/build post-form-component nil
                      {:opts {:init-post (om/value post)
                              :after-persisted
                              (fn [new-post reset-form!]
                                (om/set-state! owner :editing? false)
                                (doseq [[k v] new-post]
                                  (om/update! post k v)))}})

            (partials/html-from-markdown (:body post)))]]
        [:div.row
          [:div.post-controls
           (when (and (:editable post) (not editing?))
             [:a {:href "#"
                  :onClick (fn [e]
                             (.preventDefault e)
                             (om/set-state! owner :editing? true))}
              "Edit"])]]]))))

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
           [:ol.list-unstyled (om/build-all post-component (:posts thread) {:key :id})]
           (om/build post-form-component nil
                     {:opts {:init-post (models/empty-post (:id thread))
                             :after-persisted
                             (fn [post reset-form!]
                               (reset-form!)
                               (om/transact! thread :posts #(conj % post)))}})]
          [:h1 "Loading..."])))))
