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
      RubyParserStub
    when :javascript
      JsParserStub
    else
      DefaultParserStub
    end
  end
end

# Простейшие заглушки для линтера
class RubyParserStub
  def initialize(_repo); end

  def run_lint
    { passed: true, violations: [] }
  end
end

class JsParserStub
  def initialize(_repo); end

  def run_lint
    { passed: true, violations: [] }
  end
end

class DefaultParserStub
  def initialize(_repo); end

  def run_lint
    { passed: true, violations: [] }
  end
end
