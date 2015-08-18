RSpec.describe Transflow do
  shared_context 'a successful transaction' do
    it 'calls all operations and return final result' do
      input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

      transflow[input]

      expect(Test::DB).to include(name: 'Jane', email: 'jane@doe.org')
    end
  end

  let(:transflow) do
    Transflow(container: operations) do
      step :preprocess, with: :preprocess_input do
        step :validate, with: :validate_input do
          step :persist, with: :persist_input
        end
      end
    end
  end

  before do
    Test::DB = []
  end

  context 'with module functions' do
    include_context 'a successful transaction' do
      let(:operations) do
        Module.new do
          extend Transproc::Registry

          import :symbolize_keys, from: Transproc::HashTransformations

          def self.preprocess_input(input)
            t(:symbolize_keys)[input]
          end

          def self.validate_input(input)
            raise StepError.new(:validate_input, 'email nil') if input[:email].nil?
            input
          end

          def self.persist_input(input)
            Test::DB << input
          end

          def self.handle_validation_error(error)
            ERRORS << error.message
          end
        end
      end
    end
  end

  context 'with custom operation objects' do
    include_context 'a successful transaction' do
      let(:operations) do
        {
          preprocess_input: -> input { { name: input['name'], email: input['email'] } },
          validate_input: -> input { input },
          persist_input: -> input { Test::DB << input }
        }
      end
    end
  end

  context 'using short DSL' do
    include_context 'a successful transaction'  do
      let(:operations) do
        {
          preprocess: -> input { { name: input['name'], email: input['email'] } },
          validate: -> input { input },
          persist: -> input { Test::DB << input }
        }
      end

      let(:transflow) do
        Transflow(container: operations) do
          publish true

          steps :preprocess, :validate, :persist
        end
      end

      it 'sets publish to true for all steps' do
        listener = spy(:listener)

        transflow.subscribe(preprocess: listener, validate: listener, persist: listener)

        transflow['name' => 'Jane', 'email' => 'jane@doe.org']

        expect(listener).to have_received(:preprocess_success)
          .with(name: 'Jane', email: 'jane@doe.org')

        expect(listener).to have_received(:validate_success)
          .with(name: 'Jane', email: 'jane@doe.org')

        expect(listener).to have_received(:persist_success)
          .with(Test::DB)
      end
    end
  end
end
