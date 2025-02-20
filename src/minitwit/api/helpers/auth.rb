module Authorization

  # Authorize api request
  def req_from_sim(req)
    puts request.env['Authorization']
    from_sim = request.env['Authorization']
    if (from_sim != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh')
       status 403
       JSON({status: 403, 'error_msg': 'You are not authorized to use this resource!'})
    end 
  end 

end
