require 'rails_helper'

RSpec.describe ResultType, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'database constraints' do
    it 'ensures name is unique' do
      ResultType.create!(name: 'win')
      duplicate_result_type = ResultType.new(name: 'win')

      expect(duplicate_result_type).not_to be_valid
      expect(duplicate_result_type.errors[:name]).to include('has already been taken')
    end
  end

  describe 'seeded results' do
    let!(:result_types) { %w[win lose draw penalty extra_time disqualified] }

    before do
      result_types.each { |name| ResultType.create!(name: name) }
    end

    it 'returns all expected result types' do
      expect(ResultType.pluck(:name)).to match_array(result_types)
    end
  end
end
