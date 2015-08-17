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
            raise 'email nil' if input[:email].nil?
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
end
