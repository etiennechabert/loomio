require 'rails_helper'

describe Api::B2::GroupsController do
  let(:group) { create :group }
  let(:user) { group.admins.first }
  let(:another_user) { create :user }

  before { user.update(api_key: 'abc123') }

  describe 'show' do
    it 'returns group by id' do
      get :show, params: { id: group.id, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['groups'][0]['id']).to eq group.id
    end

    it 'returns group by key' do
      get :show, params: { id: group.key, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['groups'][0]['key']).to eq group.key
    end

    it 'missing permission' do
      another_user.update(api_key: 'def456')
      get :show, params: { id: group.id, api_key: another_user.api_key }
      expect(response.status).to eq 403
    end

    it 'missing api_key' do
      get :show, params: { id: group.id }
      expect(response.status).to eq 403
    end
  end

  describe 'subgroups' do
    let!(:subgroup) { create :group, parent: group }

    it 'returns visible subgroups' do
      subgroup.add_member! user
      get :subgroups, params: { id: group.id, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['groups'].map { |g| g['id'] }).to include subgroup.id
    end

    it 'missing permission' do
      another_user.update(api_key: 'def456')
      get :subgroups, params: { id: group.id, api_key: another_user.api_key }
      expect(response.status).to eq 403
    end
  end

  describe 'discussions' do
    let!(:discussion) { create :discussion, group: group, author: user }

    it 'returns discussions in group' do
      get :discussions, params: { id: group.id, api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['discussions'].map { |d| d['id'] }).to include discussion.id
    end

    it 'filters closed discussions' do
      discussion.update(closed_at: Time.now)
      get :discussions, params: { id: group.id, filter: 'closed', api_key: user.api_key }
      expect(response.status).to eq 200
      json = JSON.parse response.body
      expect(json['discussions'].map { |d| d['id'] }).to include discussion.id
    end

    it 'missing permission' do
      another_user.update(api_key: 'def456')
      get :discussions, params: { id: group.id, api_key: another_user.api_key }
      expect(response.status).to eq 403
    end
  end
end
