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

    if RUBY_VERSION > '2.0.0'
      require_relative 'kw_args.rb'
      include_context 'with steps accepting kw args'
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
  end

  describe '#to_s' do
    it 'returns a string representation of a transaction' do
      transaction = Transflow::Transaction.new(three: proc {}, two: proc {}, one: proc {})

      expect(transaction.to_s).to eql('Transaction(one => two => three)')
    end
  end
end
