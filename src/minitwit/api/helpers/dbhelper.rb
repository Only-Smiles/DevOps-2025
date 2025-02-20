module DatabaseHelper
  # Database connection helper
  def connect_db(dbpath)
    SQLite3::Database.new(dbpath, results_as_hash: true)
  end

  # Query helper
  def query_db(query, args = [], one = false)
    result = @db.execute(query, args)
    one ? result.first : result
  end

  # Get user ID by username
  def get_user_id(username)
    user = query_db('SELECT user_id FROM user WHERE username = ?', [username], true)
    user ? user['user_id'] : nil
  end

end
