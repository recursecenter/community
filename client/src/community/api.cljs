(ns community.api
  (:require [community.models :as models]
            [community.util :as util :refer-macros [<? p]]
            [cljs.core.async :as async]
            [clojure.walk :refer [postwalk]]
            [clojure.string :as str]
            [community.util.ajax :as ajax])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(def api-root "/api")

(defn api-path [path]
  (str api-root path))

(def ^:private re-global-underscore
  (js/RegExp. "_" "g"))

(def ^:private re-global-dash
  (js/RegExp. "-" "g"))

(defn string-with-underscore->keyword-with-dash
  "'foo_bar' => :foo-bar"
  [s]
  (keyword (.replace s re-global-underscore "-")))

(defn keyword-with-dash->string-with-underscore
  ":foo-bar => 'foo_bar'"
  [kw]
  (.replace (name kw) re-global-dash "_"))

(defn format-keys
  [m format-key]
  (let [f (fn [[k v]] [(format-key k) v])]
    (postwalk (fn [x]
                (if (map? x)
                  (into {} (map f x))
                  x))
              m)))

(defn csrf-token []
  ;; CSRF tokens won't be checked on GET or HEAD, but we'll
  ;; send them every time regardless to make our lives easier
  (-> (.getElementsByName js/document "csrf-token")
      (aget 0)
      (.-content)))

(defn error-info [error]
  (case (:status error)
    0 [:ajax :cant-reach-server]
    [:ajax :generic]))

(defn request
  "Makes an API request to the Hacker School API with some default
  options, returning a core.async channel containing either a
  response or an ExceptionInfo error."
  ([request-fn resource]
     (request request-fn resource {}))
  ([request-fn resource opts]
     (let [out (async/chan 1)
           on-error (fn [error-res]
                      (let [err (ex-info (str "Failed to access " resource)
                                         (assoc error-res :error-info (error-info error-res)))]
                        (async/put! out err #(async/close! out))))
           on-success (fn [data]
                        (async/put! out (format-keys data string-with-underscore->keyword-with-dash) #(async/close! out)))

           default-opts {:on-success on-success
                         :on-error on-error
                         :headers {"X-CSRF-Token" (csrf-token)}}
           formatted-opts (update-in opts [:params] format-keys keyword-with-dash->string-with-underscore)]
       (request-fn (api-path resource)
                   (merge default-opts formatted-opts))
       out)))

(def GET (partial request ajax/GET))
(def POST (partial request ajax/POST))
(def PATCH (partial request ajax/PATCH))

(defn make-api-fn
  "`res-transform` transforms the response if the request is successful.
  `validate` validates the args passed to the api-fn, returning an error message
  if there is an error, or nil if there is not."
  [req-fn & {:keys [res-transform validate]
             :or {res-transform identity
                  validate (constantly nil)}}]
  (fn [& args]
    (let [out (async/chan 1)
          error-message (apply validate args)]
      (if (nil? error-message)
        (go
          (try
            (let [res (<? (apply req-fn args))]
              (>! out (res-transform res)))
            (catch ExceptionInfo e
              (>! out e))))
        (async/put! out (ex-info error-message {:message error-message})))
      out)))

(def current-user
  (make-api-fn #(GET "/users/me")
    :res-transform (partial models/api->model :user)))

(def update-settings
  (make-api-fn (fn [settings-to-update]
                 (PATCH "/settings"
                        {:params {:settings settings-to-update}
                         :format :json}))))

(def subforum-groups
  (make-api-fn #(GET "/subforum_groups")
    :res-transform #(mapv (partial models/api->model :subforum-group) %)))

(def subforum
  (make-api-fn (fn [id] (GET (str "/subforums/" id)))
    :res-transform (partial models/api->model :subforum)))

(def thread
  (make-api-fn (fn [id] (GET (str "/threads/" id)))
    :res-transform (partial models/api->model :thread)))

(def search
  (make-api-fn (fn [query filters]
                 (->> (for [[k v] filters]
                        (str "filters[" (name k) "]=" v))
                      (str/join "&")
                      (str "/search?q=" query "&")
                      (GET)))))

(def suggestions
  (make-api-fn (fn [query] (GET (str "/suggestions?q=" query)))))

(defn validate-post [post]
  (when (empty? (:body post))
    "The body of a post cannot be empty."))

(defn post->api-data [{:as post :keys [broadcast-to]}]
  (let [mentions (map :id (:mentions post))]
    {:post {:body (:body post)}
     :mentions (if (empty? mentions) nil mentions)
     :broadcast-to (if (empty? broadcast-to) nil broadcast-to)}))

(def new-post
  (make-api-fn (fn [post]
                 (POST (str "/threads/" (:thread-id post) "/posts")
                       {:params (post->api-data (dissoc post :thread-id)) :format :json}))
    :res-transform (partial models/api->model :post)
    :validate validate-post))

(def update-post
  (make-api-fn (fn [post]
                 (PATCH (str "/posts/" (:id post))
                        {:params (post->api-data (dissoc post :id)) :format :json}))
    :res-transform (partial models/api->model :post)
    :validate validate-post))

(defn validate-thread [_ {:keys [title body]}]
  (cond (and (empty? title) (empty? body))
        "A new thread must have a non-empty title and body."

        (empty? title)
        "A new thread must have a non-empty title."

        (empty? body)
        "A new thread must have a non-empty body."))

(defn thread->api-data [{:keys [title body mentions broadcast-to]}]
  (let [mention-ids (map :id mentions)]
    {:thread {:title title}
     :post {:body body}
     :mentions (if (empty? mention-ids) nil mention-ids)
     :broadcast-to (if (empty? broadcast-to) nil broadcast-to)}))

(def new-thread
  (make-api-fn (fn [subforum-id thread]
                 (POST (str "/subforums/" subforum-id "/threads")
                       {:params (thread->api-data thread)
                        :format :json}))
    :res-transform (partial models/api->model :thread)
    :validate validate-thread))

(def mark-notifications-as-read
  (make-api-fn (fn [notifications]
                 (let [ids (mapv :id notifications)]
                   (POST "/notifications/read"
                         {:params {:ids ids}
                          :format :json})))))

(def mark-welcome-message-as-read
  (make-api-fn (fn [] (POST "/welcome_message/read"))))

(def subscribe
  (make-api-fn (fn [{:keys [subscribable-id resource-name]}]
                 (POST (str "/" resource-name "s/" subscribable-id "/subscribe")))))

(def unsubscribe
  (make-api-fn (fn [{:keys [subscribable-id resource-name]}]
                 (POST (str "/" resource-name "s/" subscribable-id "/unsubscribe")))))
