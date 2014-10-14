(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.api :as api]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials :refer [link-to]]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async :refer [chan <! >! close! put! alts!]]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(def ENTER 13)
(def UP_ARROW 38)
(def DOWN_ARROW 40)
(def TAB 9)
(def ESC 27)

(def KEYS #{UP_ARROW DOWN_ARROW ENTER TAB ESC})

(def key->search-filter {:none :none :users :author :threads :thread :subforums :subforum})

(defn result->display-item
  "Given a suggestions result, convert to valid display item in the autocomplete menu"
  [key text {:keys [id slug] :or {id nil :slug nil}}]
  (let [search-filter (key->search-filter key)
        display-text (condp = search-filter
                      :none
                        (str "Search for " text)
                      :author
                        (str "Narrow to posts by: " text)
                      :thread
                        (str "Narrow to thread: " text)
                      :subforum
                        (str "Narrow to subforum: " text))]
      {:search-filter search-filter :text text :display display-text :id id :slug slug
       :search-str (str (name search-filter) ":(" text ")")}))

(defn results->display-list
  "Given all results from the suggestions endpoint, return list of things to show in the autocomplete menu"
  [q results]
  (let [always-display (result->display-item :none q nil)
        display (mapcat
                  (fn [key result-set]
                    (when (not (empty? result-set))
                      (map
                        (fn [result]
                          (result->display-item key (:text result) (:payload result)))
                        result-set)))
                  (keys results) (vals results))]
    (conj display always-display)))

(defn display [show]
  (if show {} {:display "none"}))

(defn completion [{:keys [search-filter text display id slug search-str]}]
  (condp = search-filter
    :author (routes :search {:query search-str})
    :thread (routes :thread {:id id :slug slug})
    :subforum (routes :subforum {:id id :slug slug})
    :none (routes :search {:query text})))

(defcomponent suggestions-view [{:keys [query suggestions]} owner]
  (display-name [_] "Search suggestions")

  (init-state [_]
    {:hidden true})

  (will-mount [_]
    (let [hide (om/get-state owner :hide)]
      (go-loop []
        (let [[v ch] (alts! [hide])]
          (cond
            (= ch hide)
              (om/set-state! owner :hidden v))
        (recur)))))

  (render-state [_ {:keys [hide hidden]}]
    (let [results (results->display-list query suggestions)]
    (html
      [:div.list-group
        {:id "suggestions" :ref "suggestions"
         :style (display (and (not hidden) (not (empty? query))))}
        (map
          (fn [data]
            (partials/link-to (completion data) {:class "list-group-item"} (:display data)))
          results)]))))

(defn search [owner]
  (let [input (om/get-node owner "search-query")
        query (-> input .-value)]
    (routes/redirect-to (routes :search {:query query}))))

(defn handle-input-change [query owner]
  (controller/dispatch :update-search-suggestions query)
  (om/set-state! owner :query query))

(defn handle-key-down []

  )
(defcomponent input-view [app owner]
  (display-name [_] "Search Input")

  (render-state [_ {:keys [query hide]}]
    (html
      [:div
        [:form.form-inline
          {:name "search-form"
           :onSubmit (fn [e]
                       (.preventDefault e)
                       (search owner))}
            [:input.form-control {:ref "search-query"
                                  :type "text"
                                  :style {:height "26px"}
                                  :value query
                                  :onFocus (fn [e] (put! hide false))
                                  :onBlur (fn [e] (js/setTimeout #(put! hide true) 100))
                                  :onKeyDown (fn [e] (handle-key-down e))
                                  :onChange (fn [e]
                                              (handle-input-change
                                                (.. e -target -value) owner))}]]])))

(defn handle-keys-pressed [e]
  (do  (.log js/console e)))

(defcomponent autocomplete [app owner]
  (display-name [_] "Autocomplete")

  (init-state [_]
    {:query "" :hide (chan) })

  (will-mount [_]
    (.addEventListener js/window "keyup" handle-keys-pressed))

  (render-state [_ state]
    (html
      [:div
        (->input-view app {:init-state state})
        (->suggestions-view app {:init-state state})])))

(defcomponent result [{:keys [-source] :as result}]
  (display-name [_] "Result")

  (render [_]
    (html
      [:div.row.col-md-offset-1.col-md-9.search-result
       [:div.row.header
        [:div.col-md-8 (link-to (routes :thread {:id (:thread-id -source)
                                                 :slug (:thread-slug -source)
                                                 :post-number (:post-number -source)})
                                {:style {:color (:ui-color -source)}}
                                [:h4.thread-title (:thread -source)])]
        [:div.col-md-4 (link-to (routes :subforum {:id (:subforum-id -source)
                                                   :slug (:subforum-slug -source)})
                                {:style {:color (:ui-color -source)}}
                                [:h5 (:subforum-group -source)
                                     " / "
                                     (:subforum -source)])]]
      [:div.body (partials/html-from-markdown (:body -source))]
      [:div.row.footer
       [:div.col-md-10 [:a {:href (routes/hs-route
                                    :person {:hacker-school-id (:hacker-school-id -source)})}
                           (:author -source)]]
       [:div.col-md-2  (link-to (routes :thread {:id (:thread-id -source)
                                                 :slug (:thread-slug -source)
                                                 })
                                {:style {:color (:ui-color -source)}}
                                "View thread ->")]]])))

(defcomponent search-results [{:keys [search] :as app} owner]
  (display-name [_] "Search Results")

  (render [_]
    (let [results (:results search)]
      (if (empty? results)
        (html
          [:div
           "Sorry, there were no matching results for this search."])
        (html
          [:div
            [:div.col-md-offset-1 [:h4 "Search Results"]]
            [:div.results (map (partial ->result) results)]])))))
