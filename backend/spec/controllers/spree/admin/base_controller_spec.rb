# Spree's rpsec controller tests get the Spree::ControllerHacks
# we don't need those for the anonymous controller here, so
# we call process directly instead of get
require 'spec_helper'

describe Spree::Admin::BaseController do

  controller(Spree::Admin::BaseController) do
    def index
      render :text => 'test'
    end
  end

  describe "check alerts" do
    it "checks alerts with before_filter" do
      controller.should_receive :check_alerts
      process :index
    end

    it "saves alerts into session" do
      controller.stub(:should_check_alerts? => true)
      Spree::Alert.should_receive(:current).and_return([{"id" => "1", "message" => "test alert", "severity" => 'release'}])
      process :index
      session[:alerts].first["message"].should eq "test alert"
    end

    describe "should_check_alerts?" do
      before do
        Rails.env.stub(:production? => true)
        Spree::Config[:check_for_spree_alerts] = true
        Spree::Config[:last_check_for_spree_alerts] = nil
      end

      it "only checks alerts if production and preference is true" do
        controller.send(:should_check_alerts?).should be_true
      end

      it "only checks for production" do
        Rails.env.stub(:production? => false)
        controller.send(:should_check_alerts?).should be_false
      end

      it "only checks if preference is true" do
        Spree::Config[:check_for_spree_alerts] = false
        controller.send(:should_check_alerts?).should be_false
      end
    end

    describe "#generate_api_key" do
      let(:user) { mock_model(Spree.user_class) }

      before do
        controller.stub :authorize_admin => true
        controller.stub :try_spree_current_user => user
      end

      it "generates the API key for a user when they visit" do
        user.should_receive(:spree_api_key).and_return(nil)
        user.should_receive(:generate_spree_api_key!)
        process 'index'
      end

      it "does not attempt to regenerate the API key if the key is already set" do
        user.should_receive(:spree_api_key).and_return('fake')
        user.should_not_receive(:generate_spree_api_key!)
        process 'index'
      end
    end
  end
end
