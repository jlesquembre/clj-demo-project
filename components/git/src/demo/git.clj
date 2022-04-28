(ns demo.git
  (:require
    [babashka.fs :as fs]))


(defn demo
  []
  (fs/exists? "/tmp/somedir"))
