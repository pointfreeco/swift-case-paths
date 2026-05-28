import Foundation

// NB: This is adapted from Custom Dump and should ideally be kept in sync.
package func typeName(_ type: Any.Type) -> String {
  var name = _typeName(type, qualified: true)
    .replacingOccurrences(
      of: #"\(unknown context at \$[[:xdigit:]]+\)\."#,
      with: "",
      options: .regularExpression
    )
  for _ in 1...10 {  // NB: Only handle so much nesting
    let abbreviated =
      name
      .replacingOccurrences(
        of: #"\bSwift.Optional<([^><]+)>"#,
        with: "$1?",
        options: .regularExpression
      )
      .replacingOccurrences(
        of: #"\bSwift.Array<([^><]+)>"#,
        with: "[$1]",
        options: .regularExpression
      )
      .replacingOccurrences(
        of: #"\bSwift.Dictionary<([^,<]+), ([^><]+)>"#,
        with: "[$1: $2]",
        options: .regularExpression
      )
    if abbreviated == name { break }
    name = abbreviated
  }
  name = name.replacingOccurrences(
    of: #"\w+\.([\w.]+)"#,
    with: "$1",
    options: .regularExpression
  )
  return name
}
