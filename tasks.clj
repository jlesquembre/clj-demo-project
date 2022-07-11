(ns tasks
  (:require
    [next.jdbc :as jdbc]))

(defn hello
  "Say hello"
  [x]
  (println "hello, " x))


(def db "jdbc:sqlite:/tmp/db01.db")

(defn- query [q]
  (jdbc/execute! db [q]))

(defn hello-sqlite
  "Run sqlite query"
  []
  (prn (query "SELECT 'It Works from SQLITE!!!' AS MSG ")))
