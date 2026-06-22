pub type Context {
  BlockStyle(indent: Int)

  FlowStyle(prev: Context)
  FlowMapping(prev: Context)
  FlowSequence(prev: Context)
  DoubleQuotedScalar(prev: Context)
  SingleQuotedScalar(prev: Context)
  DoubleQuotedEscape(prev: Context)
}
