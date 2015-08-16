RSpec.describe 'Injecting args into operations' do
  it 'allows passing additional args prior calling transaction' do
    Test::DB = []

    operations = {
      preprocess_input: -> input { { name: input['name'], email: input['email'] } },
      validate_input: -> email, input { input[:email] == email ? input : raise('ops') },
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

    transflow.(input, validate: 'jane@doe.org')

    expect(Test::DB).to include(name: 'Jane', email: 'jane@doe.org')
  end
end

