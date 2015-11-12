require 'ox'
require 'escape_utils'

module XmlHasher
  class Handler < ::Ox::Sax
    def initialize(options = {})
      @options = options

      if options[:except]
        @exclude_tags = options[:except].map(&:to_sym) || []
      elsif options[:only]
        @accept_tags = options[:only].map(&:to_sym) || []
      end

      @current_ignore = nil
      @current_nesting = 0
      @stack = []
    end

    def to_hash
      @hash || {}
    end

    def start_element(name)
      @current_nesting += 1

      return if @current_ignore

      if ignore_tag?(name)
        @current_ignore = [name, @current_nesting]
      elsif !@ignore_content
        @stack.push(Node.new(transform(name)))
      end
    end

    def attr(name, value)
      return if @current_ignore

      unless ignore_attribute?(name)
        @stack.last.attributes[transform(name)] = escape(value) unless @stack.empty?
      end
    end

    def text(value)
      return if @current_ignore

      @stack.last.text = escape(value)
    end

    def end_element(name)
      @current_nesting -= 1

      if @current_ignore && @current_ignore != [name, @current_nesting + 1]
        return
      elsif ignore_tag?(name)
        @current_ignore = nil
      elsif @stack.size == 1
        @hash = @stack.pop.to_hash
      elsif !@stack.empty?
        node = @stack.pop
        @stack.last.children << node
      else
        {}
      end
    end

    private

    def transform(name)
      name = name.to_s.split(':').last if @options[:ignore_namespaces]
      name = Util.snakecase(name) if @options[:snakecase]
      name = name.to_sym unless @options[:string_keys]
      name
    end

    def escape(value)
      EscapeUtils.unescape_html(value)
    end

    def ignore_attribute?(name)
      @options[:ignore_namespaces] ? !name.to_s[/^(xmlns|xsi)/].nil? : false
    end

    def ignore_tag?(name)
      if defined?(@exclude_tags)
        @exclude_tags.include?(name)
      elsif defined?(@accept_tags)
        !@accept_tags.include?(name)
      else
        false
      end
    end
  end
end
