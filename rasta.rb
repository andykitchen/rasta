# module Rasta
  class Grammar
    attr_accessor :terminal
    def terminal?
      terminal != nil
    end
    
    def parse_action(&block)
      @parse_action = block
      
      self
    end
        
    def initialize(terminal = nil)
      @terminal = terminal
    end
    
    def parse(str)
      if @terminal then
        str.sub!(@terminal, "")
      else
        @parse_action.call(str)
      end      
    end
    
    def >>(right)
      left = self
      g = Grammar.new
      
      g.parse_action do |str|
        p right
        left.parse(str) and right.parse(str)
      end
      
      g
    end
    
    def /(right)
      left = self
      g = Grammar.new
      
      g.parse_action do |str|
        orig = str.dup
        if left.parse(str)
          str
        elsif right.parse(orig)
          orig
        else
          nil
        end
      end
      
      g
    end
    
  end
# end