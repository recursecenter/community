(ns community.util
  (:require [clojure.string :as str]))

(defn throw-if-err
  "Accepts a single value, throwing it if it is a JavaScript Error
  and returning it otherwise."
  [value]
  (if (instance? js/Error value)
    (throw value)
    value))

(defn map-vals
  "Map a function over the values of a map."
  [f m]
  (into {} (for [[k v] m] [k (f v)])))

(defn log [thing]
  (.log js/console thing))

(defn pad-time [n]
  (if (= 1 (count (str n)))
    (str "0" n)
    (str n)))

(defn format-month-day [date]
  (let [date-string (.toDateString date)
        date-parts (str/split date-string " ")
        this-year (.getFullYear (js/Date.))]
    (if (= this-year (.getFullYear date))
      (str/join " " (take 2 (rest date-parts)))
      (str/join " " (take 3 (rest date-parts))))))

(defn format-hour-mins [date]
  (let [hours (.getHours date)
        mins (.getMinutes date)]
    (cond (= hours 0) (str "12:" (pad-time mins) "am")
          (= hours 12) (str "12:" (pad-time mins) "pm")
          (> hours 12) (str (- hours 12) ":" (pad-time mins) "pm")
          :else (str hours ":" (pad-time mins) "am"))))

(defn human-format-time [unix-time]
  (let [date (-> (* unix-time 1000)
                 (js/Date.))
        today (js/Date.)]
    (if (= (.toDateString date) (.toDateString today))
      (format-hour-mins date)
      (format-month-day date))))

(defn pluralize [n s]
  (if (= 1 n)
    (str n " " s)
    (str n " " s "s")))

(defn reverse-find-index
  [pred v]
  (first (for [[i el] (map-indexed vector (rseq v))
               :when (pred el)]
           (- (count v) i 1))))
