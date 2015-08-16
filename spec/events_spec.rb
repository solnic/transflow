# encoding: utf-8

RSpec.describe 'Defining events for operations' do
  let(:operations) do
    {
      preprocess_input: -> input { { name: input['name'], email: input['email'] } },
      validate_input: -> input { input },
      persist_input: -> input { input }
    }
  end

  let(:email_notifier) do
    Module.new {
      def self.persist_success(user)
        Test::SENT_EMAILS << user[:name]
      end
    }
  end

  before do
    Test::SENT_EMAILS = []
  end

  specify '(⊃｡•́‿•̀｡)⊃━☆ﾟ.*･｡ﾟ' do
    transflow = Transflow(container: operations) do
      step :preprocess, with: :preprocess_input do
        step :validate, with: :validate_input do
          step :persist, with: :persist_input, publish: true
        end
      end
    end

    transflow.persist.subscribe(email_notifier)

    input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

    transflow[input]

    expect(Test::SENT_EMAILS).to include('Jane')
  end
end
