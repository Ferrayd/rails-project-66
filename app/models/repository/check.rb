# frozen_string_literal: true

class Repository
  class Check < ApplicationRecord
    belongs_to :repository, class_name: 'Repository', inverse_of: :checks

    validates :aasm_state, presence: true

    include AASM

    aasm do
      state :created, initial: true
      state :fetching
      state :fetched
      state :checking
      state :checked
      state :parsing
      state :parsed
      state :finished
      state :failed

      event :fetch do
        transitions from: :created, to: :fetching
      end

      event :mark_as_fetched do
        transitions from: :fetching, to: :fetched
      end

      event :check do
        transitions from: :fetched, to: :checking
      end

      event :mark_as_checked do
        transitions from: :checking, to: :checked
      end

      event :parse do
        transitions from: :checked, to: :parsing
      end

      event :mark_as_parsed do
        transitions from: :parsing, to: :parsed
      end

      event :mark_as_finished do
        transitions from: :parsed, to: :finished
      end

      event :mark_as_failed do
        transitions to: :failed
      end
    end

    def pending?
      !finished? && !failed?
    end
  end
end
