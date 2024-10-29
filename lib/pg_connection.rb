require 'pg'

class PgConnection
  def call
    conn = PG.connect(dbname: ENV['DB_NAME'])
    conn.type_map_for_results = PG::BasicTypeMapForResults.new conn
    conn
  end
end

PG_CONN = PgConnection.new.call
