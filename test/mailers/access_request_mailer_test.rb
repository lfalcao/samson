require_relative '../test_helper'

describe AccessRequestMailer do
  include AccessRequestTestSupport

  describe 'sends email' do
    let(:user) { users(:viewer) }
    let(:address_list) { 'jira@example.com watchers@example.com' }
    let(:prefix) { 'SAMSON ACCESS' }
    let(:hostname) { 'localhost' }
    let(:manager_email) { 'manager@example.com' }
    let(:reason) { 'Dummy reason.' }
    subject { ActionMailer::Base.deliveries.last }

    before do
      enable_access_request(address_list, prefix)
    end

    after { restore_access_request_settings }

    describe 'multiple projects' do
      before do
        Project.any_instance.stubs(:valid_repository_url).returns(true)
        Project.create!(name: 'Second project', repository_url: 'git://foo.com:hello/world.git')
        AccessRequestMailer.access_request_email(
            hostname, user, manager_email, reason, Project.all.pluck(:id)).deliver_now
      end

      it 'is from deploys@' do
        subject.from.must_equal ['deploys@samson-deployment.com']
      end

      it 'sends to configured addresses' do
        subject.to.must_equal(address_list.split << manager_email)
      end

      it 'has a correct subject' do
        subject.subject.must_match /#{user.name}/
        subject.subject.must_match /#{Role.find(user.role_id + 1).name}/
      end

      it 'includes relevant information in body' do
        subject.body.to_s.must_match /#{user.email}/
        subject.body.to_s.must_match /#{Role.find(user.role_id + 1).name}/
        subject.body.to_s.must_match /#{hostname}/
        subject.body.to_s.must_match /#{reason}/
        Project.all.each { |project| subject.body.to_s.must_match /#{project.name}/ }
      end

      describe 'no subject prefix' do
        let(:prefix) { nil }
        it 'does not include brackets if no prefix configured' do
          subject.subject.wont_match /\[.*\]/
        end
      end

      describe 'single address configured' do
        let(:address_list) { 'jira@example.com' }
        it 'handles single email address configured' do
          subject.to.must_equal([address_list, manager_email])
        end
      end

      describe 'no address configured' do
        let(:address_list) { nil }
        it 'handles no configured email address' do
          subject.to.must_equal([manager_email])
        end
      end
    end

    describe 'single project' do
      before { AccessRequestMailer.access_request_email(
          hostname, user, manager_email, reason, [projects(:test).id]).deliver_now }

      it 'includes target project name in body' do
        subject.body.to_s.must_match /#{projects(:test).name}/
      end
    end
  end
end
