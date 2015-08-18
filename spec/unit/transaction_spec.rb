require_relative 'kw_args.rb' if RUBY_VERSION > '2.0.0'

RSpec.describe Transflow::Transaction do
  subject(:transaction) { Transflow::Transaction.new(steps) }

  let(:steps) { { three: step3, two: step2, one: step1 } }

  describe '#call' do
    context 'with steps accepting a single arg' do
      let(:step1) { -> i { i + 1 } }
      let(:step2) { -> i { i + 2 } }
      let(:step3) { -> i { i + 3 } }

      it 'composes steps and calls them' do
        expect(transaction[1]).to be(7)
      end
    end

    context 'with steps accepting an array' do
      let(:step1) { -> arr { arr.map(&:succ) } }
      let(:step2) { -> arr { arr.map(&:succ) } }
      let(:step3) { -> arr { arr.map(&:succ) } }

      it 'composes steps and calls them' do
        expect(transaction[[1, 2, 3]]).to eql([4, 5, 6])
      end
    end

    context 'with steps accepting a hash' do
      let(:step1) { -> i { { i: i } } }
      let(:step2) { -> h { h[:i].succ } }
      let(:step3) { -> i { i.succ } }

      it 'composes steps and calls them' do
        expect(transaction[1]).to eql(3)
      end
    end

    context 'with curry args' do
      let(:step1) { -> arr { arr.reduce(:+) } }
      let(:step2) { -> i, j { i + j } }
      let(:step3) { -> i { i.succ } }

      it 'curries provided args for a specific step' do
        expect(transaction[[1, 2], two: 2]).to be(6)
      end

      it 'raises error when name is not a registered step' do
        expect { transaction[[1, 2], oops: 2] }.to raise_error(ArgumentError, /oops/)
      end
    end

    include_context 'with steps accepting kw args' if RUBY_VERSION > '2.0.0'

    context 'with curried publisher step' do
      let(:step1) { -> i { i + 1 } }
      let(:step2) { Transflow::Publisher.new(:step2, -> i, j { i * j + 2 }) }
      let(:step3) { -> i { i + 3 } }

      let(:listener) { spy(:listener) }

      it 'partially applies provided args for specific steps' do
        result = transaction.subscribe(two: listener).call(1, two: 2)

        expect(result).to be(9)

        expect(listener).to have_received(:step2_success)
      end
    end

    context 'when step error is raised' do
      let(:step1) { -> i { i + 1 } }
      let(:step2) { -> i { raise Transflow::StepError } }
      let(:step3) { -> i { i + 3 } }

      it 'raises transaction failed error' do
        expect { transaction[1] }.to raise_error(Transflow::TransactionFailedError)
      end
    end
  end

  describe '#subscribe' do
    let(:step1) { instance_double('Transflow::Publisher') }
    let(:step2) { instance_double('Transflow::Publisher') }
    let(:step3) { instance_double('Transflow::Publisher') }

    it 'subscribes to individual steps' do
      listener1 = double(:listener1)
      listener3 = double(:listener3)

      expect(step1).to receive(:subscribe).with(listener1)
      expect(step2).to_not receive(:subscribe)
      expect(step3).to receive(:subscribe).with(listener3)

      transaction.subscribe(one: listener1, three: listener3)
    end

    it 'subscribes to all steps' do
      listener = double(:listener)

      expect(step1).to receive(:subscribe).with(listener)
      expect(step2).to receive(:subscribe).with(listener)
      expect(step3).to receive(:subscribe).with(listener)

      transaction.subscribe(listener)
    end

    it 'subscribes many listeners to individual steps' do
      listener11 = double(:listener11)
      listener12 = double(:listener12)

      listener31 = double(:listener31)
      listener32 = double(:listener32)

      expect(step1).to receive(:subscribe).with([listener11, listener12])

      expect(step2).to_not receive(:subscribe)

      expect(step3).to receive(:subscribe).with([listener31, listener32])

      transaction.subscribe(one: [listener11, listener12], three: [listener31, listener32])
    end
  end

  describe '#to_s' do
    it 'returns a string representation of a transaction' do
      transaction = Transflow::Transaction.new(three: proc {}, two: proc {}, one: proc {})

      expect(transaction.to_s).to eql('Transaction(one => two => three)')
    end
  end
end
