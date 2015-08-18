RSpec.describe Transflow do
  let(:operations) do
    {
      validate: -> input {
        if input[:name] && input[:email]
          Right(input)
        else
          Left('that is not valid')
        end
      },
      persist: -> input {
        input.fmap { |value| Test::DB << value }
      }
    }
  end

  let(:transflow) do
    Transflow(container: operations) do
      step :validate, publish: true, monadic: true do
        step :persist, monadic: true
      end
    end
  end

  before do
    Test::DB = []
    Test::ERRORS = []
  end

  it 'calls all operations and return final result' do
    input = { name: 'Jane', email: 'jane@doe.org' }

    transflow[input]

    expect(Test::DB).to include(name: 'Jane', email: 'jane@doe.org')
  end

  it 'returns monad' do
    input = { name: 'Jane', email: 'jane@doe.org' }

    result = transflow[input].fmap { |db| db[0][:email] }

    expect(result.value).to eql('jane@doe.org')

    input = { email: 'jane@doe.org' }

    result = transflow[input]

    expect(result.value).to eql('that is not valid')
  end

  it 'triggers events' do
    input = { email: 'jane@doe.org' }

    listener = Module.new do
      def self.validate_failure(input, msg)
        Test::ERRORS << "#{input[:email]} #{msg}"
      end
    end

    transflow.subscribe(validate: listener)

    transflow[input]

    expect(Test::DB).to be_empty
    expect(Test::ERRORS).to include("jane@doe.org that is not valid")
  end
end
