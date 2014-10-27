(ns community.util.selection-list)

(defprotocol ISelectNextOrPrev
  (-select-next-or-prev [this next?]))

(defprotocol IUnselect
  (-unselect [this]))

(defprotocol IGetSelected
  (-get-selected [this]))

(defn wrapped-index
  "Given an index and a sequence, wrap the index as if the sequence were circular.
    (wrapping-index 1  [0 1 2]) => 1
    (wrapping-index 3  [0 1 2]) => 0
    (wrapping-index -1 [0 1 2]) => 2
    (wrapping-index -2 [0 1 2]) => 1
    (wrapping-index 4 [0 1 2 3]) => 0"
  [index sequence]
  (let [c (count sequence)]
    (cond
     ;; within bounds
     (< -1 index c) index
     ;; too low
     (< index 0) (- (dec c) (inc index))
     ;; too high
     (>= index c) (- index c))))

(defn index-where [pred sequence]
  (first (for [[i v] (map-indexed vector sequence)
               :when (pred v)]
           i)))

(deftype SelectionList [data selected-index]
  IGetSelected
  (-get-selected [_]
    (if selected-index (nth data selected-index) nil))

  ISelectNextOrPrev
  (-select-next-or-prev [_ next?]
    (let [next-index (+ (if selected-index selected-index -1) (if next? 1 -1))]
      (SelectionList. data (wrapped-index next-index data))))

  IUnselect
  (-unselect [_]
    (SelectionList. data nil))

  ISeqable
  (-seq [_]
    (seq
     (map-indexed (fn [i el] {:selected? (= i selected-index) :value el})
                  data))))

(defn selection-list
  ([data] (selection-list data 0))
  ([data selected-index] (->SelectionList data selected-index)))

(defn select [next-or-prev selection-list]
  (condp = next-or-prev
    :next (-select-next-or-prev selection-list true)
    :prev (-select-next-or-prev selection-list false)))

(defn unselect [selection-list]
  (-unselect selection-list))

(defn selected [selection-list]
  (-get-selected selection-list))
