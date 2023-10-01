//enum Overloaded: CasePathable {
//  case result(int: Int)
//  case result(string: String)
//
//  public struct AllCasePaths {
//    @CasePathable
//    public enum Result {
//      case int(Int)
//      case string(String)
//    }
//    public var result: Case<Overloaded, Result> {
//      Case(
//        embed: {
//          switch $0 {
//          case let .int(int): .result(int: int)
//          case let .string(string): .result(string: string)
//          }
//        },
//        extract: {
//          switch $0 {
//          case let .result(int: int): .int(int)
//          //        ╰ 🛑 Ambiguous use of 'result' (https://github.com/apple/swift/issues/51517)
//          case let .result(string: string as String): .string(string)
//          default: nil
//          }
//        }
//      )
//    }
//  }
//  public static var allCasePaths: AllCasePaths {
//    AllCasePaths()
//  }
//}
