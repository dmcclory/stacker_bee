require "spec_helper"

# TODO: does this really need to work with nested hashes?
describe StackerBee::Middleware::RemoveEmptyStrings do
  let(:middleware) do
    described_class.new(app: proc { |env| @response_env = env })
  end
  let(:env) { StackerBee::Middleware::Environment.new }
  # TODO: rename response_env
  let(:response_env) { @response_env }
  let(:params) { response_env.request.params }

  before do
    env.request.params = {
      blank: '',
      ok1: true,
      ok2: nil,
      ok3: 'string',
      ok4: ' ',

      nested: {
        blank: '',
        ok1: true,
        ok2: nil,
        ok3: 'string',
        ok4: ' ',

        nested: {
          blank: '',
          ok1: true,
          ok2: nil,
          ok3: 'string',
          ok4: ' '
        }
      }
    }
  end

  before do
    middleware.call(env)
  end

  it "removes empty strings from the input" do
    params.keys.should =~ [:ok1, :ok2, :ok3, :ok4, :nested]
  end

  it "removes empty strings nested in hashes" do
    params[:nested].keys.should =~ [:ok1, :ok2, :ok3, :ok4, :nested]
  end

  it "removes empty strings deeply nested in hashes" do
    params[:nested][:nested].keys.should =~ [:ok1, :ok2, :ok3, :ok4]
  end
end
