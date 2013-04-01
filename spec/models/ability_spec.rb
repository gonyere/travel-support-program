require 'spec_helper'
require 'cancan/matchers'
#require 'ruby-debug'

describe Ability do
  fixtures :users, :user_profiles, :events, :requests, :state_transitions
  
  subject { Ability.new(user) }

  context 'when is a requester' do
    let(:user){ users(:luke) }

    context 'managing events' do
      it{ should be_able_to(:create, Event.new) }
      it{ should_not be_able_to(:update, events(:javin_hackaton)) }
      it{ should be_able_to(:update, events(:party)) }
      it{ should_not be_able_to(:destroy, events(:javin_hackaton)) }
      it{ should_not be_able_to(:destroy, events(:party)) }
    end

    context 'managing his own requests' do
      it{ should be_able_to(:create, Request.new) }
      it{ should be_able_to(:read, requests(:luke_for_party)) }
      it{ should be_able_to(:read, requests(:luke_for_javin)) }
      it{ should be_able_to(:update, requests(:luke_for_party)) }
      it{ should_not be_able_to(:update, requests(:luke_for_javin)) }
      it{ should be_able_to(:destroy, requests(:luke_for_party)) }
      it{ should_not be_able_to(:destroy, requests(:luke_for_javin)) }
      it{ should be_able_to(:cancel, requests(:luke_for_party)) }
      it{ should_not be_able_to(:cancel, requests(:luke_for_javin)) }
    end

    context "trying to look into other's requests" do
      it{ should_not be_able_to(:read, requests(:wedge_for_javin)) }
      it{ should_not be_able_to(:read, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:update, requests(:wedge_for_party)) }
    end

    context "asking for a correct reimbursement" do
      it{ should be_able_to(:create, requests(:luke_for_javin).build_reimbursement) }
    end

    context "asking for an incorrect reimbursement" do
      let(:user){ users(:wedge) }
      it{ should_not be_able_to(:create, requests(:luke_for_javin).build_reimbursement) }
      it{ should_not be_able_to(:create, requests(:wedge_for_javin).build_reimbursement) }
    end

    context "managing a new reimbursement" do
      before(:each) do
        @reimbursement = requests(:luke_for_javin).create_reimbursement
      end

      it{ should be_able_to(:submit, @reimbursement) }
      it{ should be_able_to(:update, @reimbursement) }
      it{ should be_able_to(:cancel, @reimbursement) }

      context "and trying to look into other's reimbursements" do
        let(:user){ users(:wedge) }
        it{ should_not be_able_to(:read, @reimbursement) }
        it{ should_not be_able_to(:update, @reimbursement) }
        it{ should_not be_able_to(:submit, @reimbursement) }
        it{ should_not be_able_to(:cancel, @reimbursement) }
      end
    end
  end

  context 'when is a TSP member' do
    let(:user){ users(:tspmember) }

    context 'managing events' do
      it{ should be_able_to(:create, Event.new) }
      it{ should be_able_to(:update, events(:javin_hackaton)) }
      it{ should be_able_to(:update, events(:party)) }
      it{ should_not be_able_to(:destroy, events(:javin_hackaton)) }
      it{ should_not be_able_to(:destroy, events(:party)) }
    end

    context 'managing requests' do
      it{ should_not be_able_to(:create, Request.new) }
      it{ should be_able_to(:read, requests(:wedge_for_party)) }
      it{ should be_able_to(:read, requests(:luke_for_javin)) }
      it{ should be_able_to(:update, requests(:wedge_for_party)) }
      it{ should be_able_to(:approve, requests(:wedge_for_party)) }
      it{ should be_able_to(:roll_back, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:update, requests(:luke_for_javin)) }
      it{ should_not be_able_to(:destroy, requests(:luke_for_party)) }
      it{ should_not be_able_to(:destroy, requests(:luke_for_javin)) }
      it{ should be_able_to(:cancel, requests(:luke_for_party)) }
      it{ should be_able_to(:cancel, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:cancel, requests(:luke_for_javin)) }
    end

    context "managing reimbursements" do
      before(:each) do
        @reimbursement = requests(:luke_for_javin).create_reimbursement
      end

      it{ should_not be_able_to(:create, Reimbursement.new) }
      it{ should be_able_to(:read, @reimbursement) }
      it{ should be_able_to(:cancel, @reimbursement) }
      it{ should_not be_able_to(:update, @reimbursement) }
      it{ should_not be_able_to(:approve, @reimbursement) }
      it{ should_not be_able_to(:roll_back, @reimbursement) }
      it{ should_not be_able_to(:destroy, @reimbursement) }

      context "already submitted" do
        before(:each) do
          @reimbursement.submit!
        end

        it{ should be_able_to(:read, @reimbursement) }
        it{ should be_able_to(:update, @reimbursement) }
        it{ should be_able_to(:approve, @reimbursement) }
        it{ should be_able_to(:roll_back, @reimbursement) }
        it{ should be_able_to(:cancel, @reimbursement) }
        it{ should_not be_able_to(:destroy, @reimbursement) }
        it{ should_not be_able_to(:authorize, @reimbursement) }

        context "and approved" do
          before(:each) do
            @reimbursement.approve!
          end

          it{ should be_able_to(:read, @reimbursement) }
          it{ should_not be_able_to(:cancel, @reimbursement) }
          it{ should_not be_able_to(:update, @reimbursement) }
          it{ should_not be_able_to(:approve, @reimbursement) }
          it{ should_not be_able_to(:destroy, @reimbursement) }
          it{ should_not be_able_to(:roll_back, @reimbursement) }
          it{ should_not be_able_to(:authorize, @reimbursement) }

          context "and authorized" do
            before(:each) do
              @reimbursement.authorize!
            end

            it{ should be_able_to(:read, @reimbursement) }
            it{ should_not be_able_to(:update, @reimbursement) }
            it{ should_not be_able_to(:approve, @reimbursement) }
            it{ should_not be_able_to(:cancel, @reimbursement) }
            it{ should_not be_able_to(:destroy, @reimbursement) }
            it{ should_not be_able_to(:roll_back, @reimbursement) }
            it{ should_not be_able_to(:authorize, @reimbursement) }
          end
        end
      end
    end
  end

  context 'when is an administrative' do
    let(:user){ users(:administrative) }

    context 'managing events' do
      it{ should be_able_to(:create, Event.new) }
      it{ should_not be_able_to(:update, events(:javin_hackaton)) }
      it{ should be_able_to(:update, events(:party)) }
      it{ should_not be_able_to(:destroy, events(:javin_hackaton)) }
      it{ should_not be_able_to(:destroy, events(:party)) }
    end

    context 'managing requests' do
      it{ should_not be_able_to(:create, Request.new) }
      it{ should be_able_to(:read, requests(:wedge_for_party)) }
      it{ should be_able_to(:read, requests(:luke_for_javin)) }
      it{ should_not be_able_to(:update, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:approve, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:roll_back, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:update, requests(:luke_for_javin)) }
      it{ should_not be_able_to(:destroy, requests(:luke_for_party)) }
      it{ should_not be_able_to(:destroy, requests(:luke_for_javin)) }
      it{ should_not be_able_to(:cancel, requests(:luke_for_party)) }
      it{ should_not be_able_to(:cancel, requests(:wedge_for_party)) }
      it{ should_not be_able_to(:cancel, requests(:luke_for_javin)) }
    end

    context "managing reimbursements" do
      before(:each) do
        @reimbursement = requests(:luke_for_javin).create_reimbursement
      end

      it{ should_not be_able_to(:create, Reimbursement.new) }
      it{ should be_able_to(:read, @reimbursement) }
      it{ should_not be_able_to(:update, @reimbursement) }
      it{ should_not be_able_to(:approve, @reimbursement) }
      it{ should_not be_able_to(:roll_back, @reimbursement) }
      it{ should_not be_able_to(:cancel, @reimbursement) }
      it{ should_not be_able_to(:destroy, @reimbursement) }

      context "already submitted" do
        before(:each) do
          @reimbursement.submit!
        end

        it{ should be_able_to(:read, @reimbursement) }
        it{ should_not be_able_to(:update, @reimbursement) }
        it{ should_not be_able_to(:approve, @reimbursement) }
        it{ should_not be_able_to(:roll_back, @reimbursement) }
        it{ should_not be_able_to(:cancel, @reimbursement) }
        it{ should_not be_able_to(:destroy, @reimbursement) }
        it{ should_not be_able_to(:authorize, @reimbursement) }

        context "and approved" do
          before(:each) do
            @reimbursement.approve!
          end

          it{ should be_able_to(:read, @reimbursement) }
          it{ should_not be_able_to(:update, @reimbursement) }
          it{ should_not be_able_to(:approve, @reimbursement) }
          it{ should_not be_able_to(:cancel, @reimbursement) }
          it{ should_not be_able_to(:destroy, @reimbursement) }
          it{ should be_able_to(:roll_back, @reimbursement) }
          it{ should be_able_to(:authorize, @reimbursement) }

          context "and authorized" do
            before(:each) do
              @reimbursement.authorize!
            end

            it{ should be_able_to(:read, @reimbursement) }
            it{ should_not be_able_to(:update, @reimbursement) }
            it{ should_not be_able_to(:approve, @reimbursement) }
            it{ should_not be_able_to(:cancel, @reimbursement) }
            it{ should_not be_able_to(:destroy, @reimbursement) }
            it{ should_not be_able_to(:roll_back, @reimbursement) }
            it{ should_not be_able_to(:authorize, @reimbursement) }
          end
        end
      end
    end
  end
end