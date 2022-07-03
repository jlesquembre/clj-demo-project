(require '[next.jdbc :as jdbc])

(def db "jdbc:sqlite:/tmp/db01.db")

(defn query [q]
  (jdbc/execute! db [q]))

(prn (query "SELECT 'It Works from SQLITE!!!' AS MSG "))
