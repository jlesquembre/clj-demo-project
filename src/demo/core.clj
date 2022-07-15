(ns demo.core
  (:require
    [next.jdbc :as jdbc]
    [next.jdbc.connection :as connection])
  (:import (com.zaxxer.hikari HikariDataSource))
  (:gen-class))

(def ^:private db-spec {:dbtype "postgresql"
                        :dbname "postgres"
                        :username "postgres"
                        :password "xxx"})
(defn -main
  [& args]
  (with-open [^HikariDataSource ds (connection/->pool HikariDataSource db-spec)]
    ;; this code initializes the pool and performs a validation check:
    (.close (jdbc/get-connection ds))
    ;; otherwise that validation check is deferred until the first connection
    ;; is requested in a regular operation:
    (prn (jdbc/execute! ds ["select 1"]))))
