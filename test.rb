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

    s = Sequence.new(peek, morea, RuleRef.new{b}, peek2)
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
        
    assert_equal(true,  s.parse?("((128 a2) abc)"))
    assert_equal(false, s.parse?("((a)"))
  end
  
  def sexp_grammar_plus
    # def list(item, sep)
    #   item >> 
    # end
    
    sexp = nil
    
    ident  = (t(/[A-z]/) >> t(/[A-z0-9]/).star).mk_s
    number = t(/[0-9]+/).mk_i
    
    atom   = ident | number
    space  = t(/\s/).plus.drop
    ospace = t(/\s/).star.drop
    
    rsexp = ref{sexp}
    
    inner = rsexp << (space >> rsexp).star.flat
    
    lparen = (t("(") >> ospace).drop
    rparen = (ospace >> t(")")).drop
    
    sexp = lparen << inner >> rparen | atom
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
  
  def arith_grammar
    exp  = nil
    sum  = nil
    rexp = ref{sum}
    
    value   = t(/[0-9\.]+/).mk_i | t("(") >> rexp >> t(")")
    factor  = value  >> ((t("*") | t("/")) >> value).star
    sum     = seq(factor) >> ((t("+") | t("-")) >> factor).star
    
    exp     = sum
    
  end
  
  def arith_grammar_plus    
    exp  = nil
    sum  = nil
    fac  = nil

    def infix(rule, sym)
      BoxAction.new(rule, sym).flat
    end

    num = t(/[0-9]+/)
    enc = t("(").drop >> ref{exp} >> t(")").drop
    enc.trans = true
    grp = enc | num
    
    mul = grp >> t("*").drop >> ref{fac}
    mul.name = "rule:mul"
    
    div = grp >> t("/").drop >> ref{fac}
    div.name = "rule:div"    
    
    fac = infix(mul, :*) | infix(div, :/) | grp

    add = fac >> t("+").drop >> ref{sum}
    add.name = "rule:add"
    
    sub = fac >> t("-").drop >> ref{sum}
    sub.name = "rule:sub"
    
    sum = infix(add, :+) | infix(sub, :-) | fac

    exp = sum
    
    # p exp

    exp
  end
  
  $arith_str = "1+2*3*10+4"
  
  def test_arith
    s = arith_grammar
    
    # s.parse_str($arith_str*1000, TreeBuilder.new)
    
    assert_equal(true,  s.parse?("1+2*3/4-1+(2*3)"))
    assert_equal(false, s.parse?("1++3-()"))
  end
  
  def test_arith_plus
    s = arith_grammar_plus
    
    p s.parse_str($arith_str, TreeBuilder.new)
  end
  
end
