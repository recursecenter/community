(ns community.components.thread
  (:require [community.util :refer-macros [<?]]
            [community.api :as api]
            [community.models :as models]
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
        [:li {:key (:id post)}
         (if editing?
           (om/build post-form-component nil
                     {:opts {:init-post (om/value post)
                             :after-persisted
                             (fn [new-post reset-form!]
                               ;; TODO: this causes a React error for
                               ;; forceUpdate of a unmounted
                               ;; component. dnolen has a fix and is
                               ;; pushing a new release of om with it
                               ;; soon.
                               (om/set-state! owner :editing? false)
                               (doseq [[k v] new-post]
                                 (om/update! post k v)))}})
           [:div
            [:div (:body post)]
            [:div (:name (:author post))]
            [:a {:href "#"
                 :onClick (fn [e]
                            (.preventDefault e)
                            (om/set-state! owner :editing? true))}
             "Edit"]])]))))

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
                             :after-persisted
                             (fn [post reset-form!]
                               (reset-form!)
                               (om/transact! thread :posts #(conj % post)))}})]
          [:h1 "Loading..."])))))
