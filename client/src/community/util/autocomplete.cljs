(ns community.util.autocomplete
  (:require [clojure.string :as str]))

(defprotocol ICursorPosition
  (-cursor-position [this]))
(defprotocol ISetCursorPosition
  (-set-cursor-position [this pos]))
(defprotocol IValue
  (-value [this]))
(defprotocol ISetValue
  (-set-value [this value]))

(defn cursor-position [x]
  (-cursor-position x))
(defn set-cursor-position [x pos]
  (-set-cursor-position x pos))
(defn value [x]
  (-value x))
(defn set-value [x value]
  (-set-value x value))

(extend-type js/HTMLElement
  ICursorPosition
  (-cursor-position [textarea]
    (.-selectionStart textarea))
  ISetCursorPosition
  (-set-cursor-position [textarea pos]
    (.setSelectionRange textarea pos pos)
    textarea))

(defrecord Autocompleter [value cursor-position]
  ICursorPosition
  (-cursor-position [_] cursor-position)
  ISetCursorPosition
  (-set-cursor-position [_ pos] (Autocompleter. value pos))
  IValue
  (-value [_] value)
  ISetValue
  (-set-value [_ v] (Autocompleter. v cursor-position)))

(def autocompleter ->Autocompleter)

(defn starts-with? [s substring]
  (zero? (.indexOf s substring)))

(defn case-insensitive-matches [substring terms {:keys [on]}]
  (let [lower-case-substring (str/lower-case substring)]
    (filter (fn [term]
              (-> ((or on identity) term)
                  (str/lower-case)
                  (starts-with? lower-case-substring)))
            terms)))

(defn query-start-index [s pos marker]
  (let [end-search (max (- pos 100) -1)]
    (loop [i (dec pos)]
      (cond (= i end-search) nil
            (= (.charAt s i) marker) (inc i)
            :else (recur (dec i))))))

(defn extract-query [textarea {:keys [marker]}]
  (assert marker)
  (when-let [start (query-start-index (-value textarea)
                                      (-cursor-position textarea)
                                      marker)]
    (.substring (-value textarea) start (-cursor-position textarea))))

(defn possibilities [textarea terms {:keys [on marker]}]
  (assert marker)
  (when-let [query (extract-query textarea {:marker marker})]
    (case-insensitive-matches query terms {:on on})))

(defn insert [textarea selection {:keys [marker]}]
  (assert marker)
  (let [selection (str selection " ")
        pos (-cursor-position textarea)
        val (-value textarea)
        start (query-start-index val pos marker)]
    (-> textarea
        (-set-value (str (.substring val 0 start)
                         selection
                         (.substring val pos)))
        (-set-cursor-position (+ start (count selection))))))
