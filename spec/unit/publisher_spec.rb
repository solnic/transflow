RSpec.describe Transflow::Publisher do
  describe '#curry' do
    it 'returns a curried publisher' do
      op = -> i, j { i + j }
      publisher = Transflow::Publisher.new(:step, op).curry

      expect(publisher.arity).to be(2)
      expect(publisher.(1).(2)).to be(3)
    end

    it 'supports callable objects' do
      op = Class.new { define_method(:call) { |i, j| i + j } }.new

      publisher = Transflow::Publisher.new(:step, op).curry

      expect(publisher.arity).to be(2)
      expect(publisher.(1).(2)).to be(3)
    end

    it 'raises error when arity is < 0' do
      op = -> *args { }

      expect {
        Transflow::Publisher.new(:step, op).curry
      }.to raise_error(/arity is < 0/)
    end

    it 'triggers event listener' do
      listener = spy(:listener)

      op = -> i, j { i + j }
      publisher = Transflow::Publisher.new(:step, op).curry

      publisher.subscribe(listener)

      expect(publisher.(1).(2)).to be(3)
      expect(listener).to have_received(:step_success).with(3)
    end
  end

  describe '#subscribe' do
    it 'subscribes one object' do
      publisher = Transflow::Publisher.new(:step, -> {})
      sub = double

      publisher.subscribe(sub)

      expect(publisher.listeners).to eql([sub])
    end

    it 'subscribes many objects' do
      publisher = Transflow::Publisher.new(:step, -> {})

      sub1 = double
      sub2 = double

      publisher.subscribe([sub1, sub2])

      expect(publisher.listeners).to eql([sub1, sub2])
    end
  end

  describe '#call' do
    context 'using exceptions' do
      subject(:publisher) { Transflow::Publisher[:divide, op] }

      let(:listener) { spy(:listener) }

      context 'when step error is raised' do
        let(:op) { -> i, j { j.zero? ? raise(Transflow::StepError, error) : i/j } }
        let(:error) { "well, j was zero, sorry mate" }

        it 'broadcasts failure' do
          publisher.subscribe(listener)

          expect {
            expect(publisher.(4, 0).value).to eql(error.value)
          }.to raise_error(Transflow::StepError, error)

          expect(listener).to have_received(:divide_failure)
        end
      end

      context 'when other error is raised' do
        let(:op) { -> i, j { i/j } }

        it 'broadcasts failure' do
          publisher.subscribe(listener)

          expect {
            expect(publisher.(4, 0).value).to eql(error.value)
          }.to raise_error(ZeroDivisionError)

          expect(listener).to_not have_received(:divide_failure)
        end
      end
    end

    context 'using monads' do
      subject(:publisher) { Transflow::Publisher[:divide, op, monadic: true] }

      let(:listener) { spy(:listener) }

      let(:op) { -> i, j { j.zero? ? error : Right(i / j) } }
      let(:error) { Left("well, j was zero, sorry mate") }

      it 'broadcasts success with Right result' do
        publisher.subscribe(listener)

        expect(publisher.(4, 2).value).to be(2)

        expect(listener).to have_received(:divide_success).with(2)
      end

      it 'broadcasts failure with Left result' do
        publisher.subscribe(listener)

        expect(publisher.(4, 0).value).to eql(error.value)

        expect(listener).to have_received(:divide_failure).with(4, 0, error.value)
      end
    end
  end
end
