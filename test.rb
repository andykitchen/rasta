require "rasta"
require "test/unit"

class TestGrammarRules < Test::Unit::TestCase
include Rasta

  def abc_grammar_classes
    a = nil
    b = nil

    ta = Terminal.new(/a/)
    tb = Terminal.new(/b/)
    tc = Terminal.new(/c/)

    peek  = Peek.new(Sequence.new(RuleRef.new{a}, tc))
    peek2 = Peek.new(Terminal.new(/[abc]/), true)
    morea = More.new(ta, 1)
    a = Sequence.new(ta, More.new(RuleRef.new{a}, 0, 1), tb)
    b = Sequence.new(tb, More.new(RuleRef.new{b}, 0, 1), tc)

    Sequence.new(peek, morea, RuleRef.new{b}, peek2)
  end

  def abc_grammar
    a = nil
    b = nil

    ta = t("a")
    tb = t("b")
    tc = t("c")

    peek  = has(ref{a} >> tc)
    peek2 = has_not(t(/[abc]/))

    morea = ta.plus

    a = seq ta, ref{a}.opt, tb
    b = seq tb, ref{b}.opt, tc

    seq peek, morea, ref{b}, peek2
  end

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
  
  def sexp_grammar
    sexp = nil
    
    ident  = t(/[A-z]/) >> t(/[A-z0-9]/).star
    number = t(/[0-9]+/)
    
    atom   = ident | number
    space  = t(/\s+/)
    
    inner = (ref{sexp} >> (space >> ref{sexp}).star)
    
    sexp = t("(") >> inner >> t(")") | atom
  end
  
  def test_sexp
    s = sexp_grammar
    
    p(s.run_parse("((128 a2) abc)"))
    
    assert_equal(true,  s.parse?("((128 a2) abc)"))
    assert_equal(false, s.parse?("((a)"))
  end
end
