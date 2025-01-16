class ResultType < ApplicationRecord

  validates :name, presence: true, uniqueness: true


  scope :available_results, -> { pluck(:name) }


  before_save :normalize_name

  private

  def normalize_name
    self.name = name.strip.downcase
  end
end
