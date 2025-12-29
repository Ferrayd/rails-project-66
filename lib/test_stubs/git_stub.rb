# frozen_string_literal: true

class GitStub
  def self.clone(repo_url, path)
    # Заглушка для git clone - просто возвращаем успех
    [0]
  end
end

