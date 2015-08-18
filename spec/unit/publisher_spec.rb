RSpec.describe Transflow::Publisher do
  describe '#curry' do
    it 'returns a curried publisher' do
      op = -> i, j { i + j }
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
  end
end
