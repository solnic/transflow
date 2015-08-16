RSpec.describe Transflow do
  let(:transflow) do
    Transflow(container: fns) do
      step :preprocess, with: :preprocess_input do
        step :validate, with: :validate_input do
          step :persist, with: :persist_input
        end
      end
    end
  end

  let(:fns) do
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
        DB << input
      end

      def self.handle_validation_error(error)
        ERRORS << error.message
      end
    end
  end

  before do
    DB = []
  end

  it 'allows defining a business transaction flow' do
    input = { 'name' => 'Jane', email: 'jane@doe.org' }

    transflow[input]

    expect(DB).to include(name: 'Jane', email: 'jane@doe.org')
  end
end
