pub type Yaml {
  Null
  Bool(Bool)
  Int(Int)
  Float(Float)
  PosInf
  NegInf
  Nan
  String(String)
  Sequence(List(Yaml))
  Mapping(List(#(Yaml, Yaml)))
}
