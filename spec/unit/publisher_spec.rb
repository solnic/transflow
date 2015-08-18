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
end
