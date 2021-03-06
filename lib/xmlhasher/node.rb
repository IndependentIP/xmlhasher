module XmlHasher
  class Node
    attr_accessor :name, :attributes, :children, :text

    def initialize(name)
      @name = name
      @attributes = {}
      @children = []
    end

    def to_hash
      h = {}
      if text
        h[name] = text
      else
        h[name] = attributes.inject({}) { |r, (key, value)| r[key] = value if !value.nil? && !value.to_s.empty?; r }
        if children.size == 1
          child = children.first
          h[name].merge!(child.to_hash)
        else
          h[name].merge!(children.group_by { |child| child.name }.inject({}) { |r, (k, v)| v.length == 1 ? r.merge!(v.first.to_hash) : r[k] = v.map { |c| c.to_hash[c.name] }; r })
        end
      end
      h[name] = nil if h[name].empty?
      h
    end
  end
end

