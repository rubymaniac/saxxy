module Saxxy
  class Helpers

    def self.camelize(obj)
      obj.to_s.split(/[^a-z0-9]/i).map(&:capitalize).join
    end

    def self.stringify_keys(hash)
      Hash[hash.map { |k, v| [k.to_s, v] }]
    end

  end
end
