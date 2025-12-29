# frozen_string_literal: true

class GitStub
  def self.clone(_repo_url, _path)
    # Заглушка для git clone - просто возвращаем успех
    [0]
  end
end
