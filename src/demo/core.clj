(ns demo.core
  (:require
    [clojure.string :as string]
    [demo.git :as g]
    [demo.mvn :as m])
  (:gen-class))

(defn -main
  [& args]
  (println (str "Hello from " (string/upper-case "clojure!!!")))
  (prn "demo.git -> " (g/demo))
  (prn "demo.mvn -> "(m/demo)))


