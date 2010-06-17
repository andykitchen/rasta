require "rasta"
require "test/unit"

require "grammars"

class TestGrammarRules < Test::Unit::TestCase
include Rasta

  def abc_assert(s)
    assert_equal(true,  s.parse?("aaabbbccc"))
    assert_equal(false, s.parse?("aaaabbbccc"))
    assert_equal(false, s.parse?("aaabbbbccc"))
    assert_equal(false, s.parse?("aaabbbcccc"))
  end

  def test_abc_classes
    abc_assert(abc_grammar_classes)
  end
  
  def test_abc
    abc_assert(abc_grammar)
  end
    
  def test_sexp
    s = sexp_grammar
        
    assert_equal(true,  s.parse?("((128 a2) abc)"))
    assert_equal(false, s.parse?("((a)"))
  end
    
  def test_sexp_plus
    s = sexp_grammar_plus
    
    str = "(abc 1 2 3 (d e f) (123) (a (123) a) ((123)))"
    
    ls = ["abc", 1, 2, 3, ["d", "e", "f"], [123],
         ["a", [123], "a"], [[123]]]
    
    # p s.parse_str(str, TreeBuilder.new)
    
    assert_equal(ls, s.parse_str(str, ArrayBuilder.new))
    
    assert_equal(true,  s.parse?("( ( 128 a2 ) abc)"))
    assert_equal(false, s.parse?("((a)"))
  end
    
  $arith_str = "1+2*3+4/(3+2)"
  
  def test_arith
    s = arith_grammar
        
    assert_equal(true,  s.parse?("1+2*3/4-1+(2*3)"))
    assert_equal(false, s.parse?("1++3-()"))
  end
  
  def test_arith_plus
    s = arith_grammar_plus
    
    p s.parse_str($arith_str, TreeBuilder.new)
  end
  
end
