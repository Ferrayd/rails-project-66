# frozen_string_literal: true

class Repository < ApplicationRecord
  belongs_to :user, class_name: 'User', inverse_of: :repositories
  has_many :checks, class_name: 'Repository::Check', dependent: :destroy

  scope :by_owner, ->(owner_user) { where(user_id: owner_user.id) }

  validates :github_id, presence: true, uniqueness: true, numericality: { only_integer: true }

  extend Enumerize

  enumerize :language, in: %i[javascript ruby]

  def language_parser_class
    case language&.to_sym
    when :ruby
      RubyParser
    when :javascript
      JavascriptParser
    else
      DefaultParser
    end
  end
end
