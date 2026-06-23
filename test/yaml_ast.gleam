pub type YamlAST {
  Null
  Bool(Bool)
  Int(Int)
  Float(Float)
  PosInf
  NegInf
  Nan
  String(String)
  Sequence(List(YamlAST))
  Mapping(List(#(YamlAST, YamlAST)))
}
