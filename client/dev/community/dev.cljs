(ns community.dev
  (:require [weasel.repl :as ws-repl]))

(defn repl-connect []
  (ws-repl/connect "ws://localhost:9001" :verbose true))
