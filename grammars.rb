require 'rasta'

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

  s = Sequence.new(peek, morea, b, peek2)
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

  seq peek, morea, b, peek2
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

def arith_grammar
  sum  = nil

  symb1 = t("*") | t("/")
  symb2 = t("+") | t("-")
  
  value   = t(/[0-9]+/) | t("(") >> ref{sum} >> t(")")
  factor  = value       >> (symb1 >> value).star
  sum     = seq(factor) >> (symb2 >> factor).star
    
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
  div = grp >> t("/").drop >> ref{fac}
  
  fac = infix(mul, :*) | infix(div, :/) | grp

  add = fac >> t("+").drop >> ref{sum}
  sub = fac >> t("-").drop >> ref{sum}
    
  sum = infix(add, :+) | infix(sub, :-) | fac

  sum.name = "sum"
  mul.name = "mul"
  div.name = "div"    
  fac.name = "fac"
  add.name = "add"
  sub.name = "sub"


  exp = sum
end

