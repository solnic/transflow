# encoding: utf-8

RSpec.describe 'Defining events for operations' do
  let(:persist_user_listener) do
    Module.new {
      def self.persist_success(user)
        Test::SENT_EMAILS << user[:name]
      end

      def self.persist_failure(user, error)
        Test::ERRORS << "#{user[:name]} - #{error.message} #{error.original_error.message}"
      end
    }
  end

  let(:transflow) do
    Transflow(container: operations) do
      step :preprocess, with: :preprocess_input do
        step :validate, with: :validate_input do
          step :persist, with: :persist_input, publish: true
        end
      end
    end
  end

  before do
    Test::SENT_EMAILS = []
    Test::ERRORS = []
  end

  context 'with success' do
    let(:operations) do
      {
        preprocess_input: -> input { { name: input['name'], email: input['email'] } },
        validate_input: -> input { input },
        persist_input: -> input { input }
      }
    end

    specify '(⊃｡•́‿•̀｡)⊃━☆ﾟ.*･｡ﾟ' do
      transflow.subscribe(persist: persist_user_listener)

      input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

      transflow[input]

      expect(Test::SENT_EMAILS).to include('Jane')
    end
  end

  context 'with failure' do
    let(:operations) do
      {
        preprocess_input: -> input { { name: input['name'], email: input['email'] } },
        validate_input: -> input { input },
        persist_input: -> input { raise Transflow::StepError.new('oops', double(message: 'OH NOEZ')) }
      }
    end

    specify '༼ つ ˵ ╥ ͟ʖ ╥ ˵༽つ' do
      transflow.subscribe(persist: persist_user_listener)

      input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

      expect { transflow[input] }.to raise_error(Transflow::TransactionFailedError)

      expect(Test::SENT_EMAILS).to be_empty
      expect(Test::ERRORS).to include("Jane - oops OH NOEZ")
    end
  end
end
