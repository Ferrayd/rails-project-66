# frozen_string_literal: true

class Repository < ApplicationRecord
  belongs_to :user, class_name: 'User', inverse_of: :repositories
  has_many :checks, class_name: 'Check', dependent: :destroy
  before_validation :assign_default_language_in_test

  scope :by_owner, ->(owner_user) { where(user_id: owner_user.id) }

  validates :github_id, presence: true, uniqueness: true, numericality: { only_integer: true }

  extend Enumerize

  enumerize :language, in: %i[javascript ruby]

  private

  def assign_default_language_in_test
    return unless Rails.env.test? && language.blank?

    self.language = 'ruby'
  end
end
