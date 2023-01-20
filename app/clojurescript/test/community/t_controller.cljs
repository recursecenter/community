(ns community.t-controller
  (:require [community.controller :as controller]
            [cljs.core.async :as async :refer [<!]]
            [jasmine.core])
  (:require-macros [jasmine.core :refer [context test is]]
                   [cljs.core.async.macros :refer [go]]))

(context "community.controller"
  (test "registering, dispatching, unregistering" [done]
    (let [c1 (controller/register)
          c2 (controller/register)]
      (go
        (controller/dispatch :message-1)

        (is = (<! c1) [:message-1])
        (is = (<! c2) [:message-1])

        (controller/dispatch :message-2)

        (is = (<! c1) [:message-2])
        (is = (<! c2) [:message-2])

        (controller/unregister c2)
        (controller/dispatch :message-3)

        (is = (<! c1) [:message-3])
        (is = [:no-message :default] (async/alts! [c2] :default :no-message))

        (done)))))
