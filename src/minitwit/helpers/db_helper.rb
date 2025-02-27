module DbHelper
  # Database connection helper
  def self.db
    @db ||= SQLite3::Database.new(MiniTwit::DATABASE, results_as_hash: true)
  end

  # Query helper
  def self.query_db(query, args = [], one = false)
    result = db.execute(query, args)
    one ? result.first : result
  end

  # Instance method to access the class methods
  def db
    DbHelper.db
  end

  def query_db(query, args = [], one = false)
    DbHelper.query_db(query, args, one)
  end

  def self.close_db
    @db&.close
    @db = nil
  end

  def close_db
    DbHelper.close_db
  end

  # Get user ID by username
  def get_user_id(username)
    user = query_db('SELECT user_id FROM user WHERE username = ?', [username], true)
    user ? user['user_id'] : nil
  end
  
  # Get user by ID
  def get_user_by_id(user_id)
    query_db('SELECT * FROM user WHERE user_id = ?', [user_id], true)
  end
  
  # Get user by username
  def get_user_by_username(username)
    query_db('SELECT * FROM user WHERE username = ?', [username], true)
  end
  
  # Get messages for timeline
  def get_timeline_messages(user_id, limit = MiniTwit::PER_PAGE)
    query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      AND (user.user_id = ? OR user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ?''',
      [user_id, user_id, limit])
  end
  
  # Get public timeline messages
  def get_public_messages(limit = MiniTwit::PER_PAGE)
    query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      ORDER BY message.pub_date DESC LIMIT ?''', [limit])
  end
  
  # Get user timeline messages
  def get_user_messages(user_id, limit = MiniTwit::PER_PAGE)
    query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE user.user_id = message.author_id AND user.user_id = ?
      ORDER BY message.pub_date DESC LIMIT ?''',
      [user_id, limit])
  end
  
  # Check if following
  def is_following?(who_id, whom_id)
    result = query_db('SELECT COUNT(*) AS count FROM follower WHERE who_id = ? AND whom_id = ?', [who_id, whom_id])
    result.first['count'].to_i > 0
  end
  
  # Add message
  def add_message(user_id, text)
    query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
            [user_id, text, Time.now.to_i])
  end
  
  # Follow user
  def follow_user(who_id, whom_id)
    query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [who_id, whom_id])
  end
  
  # Unfollow user
  def unfollow_user(who_id, whom_id)
    query_db('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', [who_id, whom_id])
  end
  
  # Get followers
  def get_followers(user_id, limit = 100)
    query_db('SELECT u.username FROM user u
              INNER JOIN follower f on f.whom_id=u.user_id
              WHERE f.who_id = ?
              LIMIT ?', [user_id, limit])
  end
end