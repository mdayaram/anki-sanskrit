# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/vedanta.json (the committed source of truth for the Vedanta glossary
# word deck). Pure reader, mirroring Letters/Gita.
module Vedanta
  def self.load(path = Paths.data("vedanta.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
