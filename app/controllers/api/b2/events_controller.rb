class Api::B2::EventsController < Api::B2::BaseController
  def index
    load_and_authorize(:discussion)
    self.collection = Event.where(discussion_id: @discussion.id)
                           .order(:sequence_id)
                           .limit(params.fetch(:per, 50).to_i)
    respond_with_collection
  end
end
