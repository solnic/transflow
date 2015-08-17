RSpec.shared_context 'with steps accepting kw args' do
  let(:step1) { -> i { { i: i, j: i + 1 } } }
  let(:step2) { -> i:, j: { i + j } }
  let(:step3) { -> i { i + 3 } }

  it 'composes steps and calls them' do
    expect(transaction[1]).to be(6)
  end
end
