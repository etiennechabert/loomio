class Api::B2::GroupsController < Api::B2::BaseController
  def show
    self.resource = load_and_authorize(:group)
    respond_with_resource
  end

  def subgroups
    self.resource = load_and_authorize(:group)
    self.collection = resource.subgroups.select { |g| current_user.can?(:show, g) }
    respond_with_collection
  end

  def discussions
    self.resource = load_and_authorize(:group)
    self.collection = DiscussionQuery.visible_to(
      user: current_user,
      group_ids: [resource.id]
    )
    self.collection = DiscussionQuery.filter(chain: collection, filter: params[:filter])
    respond_with_collection
  end
end
