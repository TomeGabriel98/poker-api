class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_#{params[:room_id]}"
  end

  def unsubscribed
    
  end

  def perform_action(data)
    ActionCable.server.broadcast("room_#{data['room_id']}", data)
  end
end
