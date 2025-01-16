class ResultType < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :available_results, -> { pluck(:name) }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.strip.downcase if name.present?
  end
end
