RSpec.describe 'Injecting args into operations' do
  it 'allows passing additional args prior calling transaction' do
    Test::DB = []

    operations = {
      preprocess_input: -> input { { name: input['name'], email: input['email'] } },
      validate_input: -> emails, input {
        emails.is_a?(Array) && emails.include?(input[:email]) ? input : raise(
          Transflow::StepError.new('email unknown'))
      },
      persist_input: -> input { Test::DB << input }
    }

    transflow = Transflow(container: operations) do
      step :preprocess, with: :preprocess_input do
        step :validate, with: :validate_input do
          step :persist, with: :persist_input
        end
      end
    end

    input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

    transflow.(input, validate: ['jane@doe.org'])

    expect(Test::DB).to include(name: 'Jane', email: 'jane@doe.org')

    expect {
      transflow.(input, validate: ['jade@doe.org'])
    }.to raise_error(Transflow::TransactionFailedError, /StepError: email unknown/)
  end
end

