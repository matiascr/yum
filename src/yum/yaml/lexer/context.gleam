pub type Context {
  BlockStyle(indent: Int)

  FlowStyle(prev: Context)
  FlowMapping(prev: Context)
  FlowSequence(prev: Context)
  BlockScalar(prev: Context, parent_indent: Int)
  DoubleQuotedScalar(prev: Context)
  SingleQuotedScalar(prev: Context)
  DoubleQuotedEscape(prev: Context)
}
