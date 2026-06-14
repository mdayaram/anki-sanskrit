# frozen_string_literal: true

# Shared filesystem locations. lib/ sits directly under the project root, so the
# root is one level up from this file.
module Paths
  ROOT         = File.expand_path("..", __dir__)
  DATA_DIR     = File.join(ROOT, "data")
  AUDIO_DIR    = File.join(DATA_DIR, "audio")
  LETTERS_JSON = File.join(DATA_DIR, "letters.json")

  # Resolve an output .txt file in the project root.
  def self.output(name)
    File.join(ROOT, name)
  end

  # Resolve a generated .json file in data/.
  def self.data(name)
    File.join(DATA_DIR, name)
  end
end
