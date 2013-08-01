class UserConsumer < Msgr::Consumer

  # TODO: Library not yet implemented
  def user_changed
    @user = User.find payload[:user_id]
    @user.posts.update_all user_name: @user.name

    response ack: true
  end
end
