require 'rails_helper'

describe Api::B2::EventsController do
  let(:group) { create :group }
  let(:user) { group.admins.first }
  let(:another_user) { create :user }
  let(:discussion) { create :discussion, group: group, author: user }

  before do
    DiscussionService.create(discussion: discussion, actor: user)
    user.update(api_key: 'abc123')
  end

  describe 'index' do
    it 'returns events for a discussion' do
      CommentService.create(comment: Comment.new(discussion: discussion, body: 'hello'), actor: user)
      get :index, params: { discussion_id: discussion.id, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['events'].length).to be >= 1
      comment_event = json['events'].find { |e| e['kind'] == 'new_comment' }
      expect(comment_event).to be_present
      expect(json['comments']).to be_present
      expect(json['comments'][0]['body']).to eq 'hello'
    end

    it 'respects per param' do
      3.times { |i| CommentService.create(comment: Comment.new(discussion: discussion, body: "msg #{i}"), actor: user) }
      get :index, params: { discussion_id: discussion.id, per: 2, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['events'].length).to eq 2
    end

    it 'missing permission' do
      another_user.update(api_key: 'def456')
      get :index, params: { discussion_id: discussion.id, api_key: another_user.api_key }
      expect(response.status).to eq 403
    end

    it 'missing api_key' do
      get :index, params: { discussion_id: discussion.id }
      expect(response.status).to eq 403
    end

    it 'missing discussion_id' do
      get :index, params: { api_key: user.api_key }
      expect(response.status).to eq 404
    end
  end
end
