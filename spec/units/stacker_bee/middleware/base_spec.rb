require 'spec_helper'

describe StackerBee::Middleware::Base do
  let(:env) { StackerBee::Middleware::Environment.new(params: params) }
  let(:params) { {} }
  let(:app) { double(:app, call: response) }
  let(:response) { double(:response) }
  let(:content_type) { double }
  before { env.response.content_type = content_type }

  let(:middleware) { subclass.new(app: app) }

  let(:subclass) { Class.new(described_class, &subclass_body) }
  let(:subclass_body) { proc {} }

  describe "#call" do
    before do
      middleware.call env
    end

    def self.it_calls_its_app_with_the_env
      it "calls its app with the env" do
        app.should have_received(:call).with(env)
      end
    end

    it_calls_its_app_with_the_env

    context "when overriding #before" do
      let(:subclass_body) do
        proc do
          def before(env)
            env.before_was_run = true
          end
        end
      end

      it_calls_its_app_with_the_env

      it "runs the before hook" do
        env.before_was_run.should be_true
      end
    end

    context "when overriding #after" do
      let(:subclass_body) do
        proc do
          def after(env)
            env.after_was_run = true
          end
        end
      end

      it_calls_its_app_with_the_env

      it "runs the after hook" do
        env.after_was_run.should be_true
      end
    end

    context "when overriding #content_types" do
      let(:subclass_body) do
        proc do
          def after(env)
            env.after_was_run = true
          end

          def content_types
            /html/
          end
        end
      end

      it_calls_its_app_with_the_env

      context "when it matches the content type" do
        let(:content_type) { 'text/html; uft-8' }
        it "runs the after hook" do
          env.after_was_run.should be_true
        end
      end

      context "when it doesn't match the content type" do
        let(:content_type) { 'text/javascript; uft-8' }
        it "runs the after hook" do
          env.after_was_run.should be_nil
        end
      end
    end

    context "when overriding #params" do
      let(:subclass_body) do
        proc do
          def params(params)
            params.merge(params_merged?: true)
          end
        end
      end

      it "changes the params" do
        env.request.params[:params_merged?].should be_true
      end
    end
  end

  describe "#endpoint_name_for" do
    let(:endpoint_name) { double }
    let(:normalized_endpoint_name) { double }

    it "delegates to its app" do
      app.should_receive(:endpoint_name_for)
        .with(endpoint_name)
        .and_return(normalized_endpoint_name)

      middleware.endpoint_name_for(endpoint_name)
        .should == normalized_endpoint_name
    end
  end

  describe "#matches_content_type?" do
    describe "by default" do
      before { env.response.content_type = '$8^02(324' }
      it "matches anything" do
        middleware.matches_content_type?(env).should be_true
      end
    end
  end
end
