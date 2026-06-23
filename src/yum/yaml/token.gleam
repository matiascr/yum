pub type BlockScalarStyle {
  Literal
  Folded
}

pub type Chomp {
  Clip
  Strip
  Keep
}

pub type Token {

  // Block Structure Indicators ================================================
  /// Denotes a block sequence entry.
  Hyphen
  /// Denotes a mapping key.
  QuestionMark
  /// Denotes a mapping value.
  Colon
  /// Ends a flow collection entry.
  Comma

  // Flow Collection Indicators ================================================
  /// Starts a flow-sequence.
  OpenSequence
  /// Ends a flow-sequence.
  CloseSequence
  /// Starts a flow-mapping.
  OpenMapping
  /// Ends a flow-mapping.
  CloseMapping

  /// Denotes a comment. `#`
  Hash

  // Document Markers ==========================================================
  /// Starts an explicit document. `---`
  DocumentStart
  /// Ends a document without starting the next one. `...`
  DocumentEnd

  // Node Property Indicators ==================================================
  /// Denotes a node’s anchor property.
  Ampersand
  /// Denotes an alias node.
  Asterisk
  /// Is used for specifying node tags. It is used to denote tag handles used in
  /// tag directives and tag properties; to denote local tags; and as the
  /// non-specific tag for non-plain scalars.
  Exclamation

  // Block Scalar Indicators ===================================================
  /// Denotes a literal block scalar.
  VerticalBar
  /// Denotes a folded block scalar.
  GreaterThan

  // Quoted Scalar Indicators ==================================================
  /// Surrounds a single-quoted flow scalar.
  SingleQuote
  /// Surrounds a double-quoted flow scalar.
  DoubleQuote

  // Directive Indicator =======================================================
  /// Denotes a directive line.
  Percent

  // Reserved ==================================================================
  /// Reserved for future use.
  At
  /// Reserved for future use.
  GraveAccent

  /// Denotes the start of a new line. `\n`
  LineBreak

  Indentation(Int)

  DoubleQuotedScalar(value: String)
  SingleQuotedScalar(value: String)
  MappingKey(value: String)
  PlainScalar(value: String)
  Anchor(value: String)
  Alias(value: String)
  Tag(value: String)
  BlockScalarHeader(style: BlockScalarStyle, chomp: Chomp, parent_indent: Int)
  BlockScalarLine(indent: Int, content: String)
  Escape(value: String)
  InvalidEscape
}
