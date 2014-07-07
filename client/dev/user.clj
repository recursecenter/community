(ns user
  (:require cemerick.piggieback weasel.repl.websocket))

(defn browser-repl []
  (cemerick.piggieback/cljs-repl
   :repl-env (weasel.repl.websocket/repl-env :port 9001)))
