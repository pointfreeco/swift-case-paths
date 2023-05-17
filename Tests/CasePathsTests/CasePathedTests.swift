import CasePaths
import XCTest

final class CasePathedTests: XCTestCase {

  enum Authentication: CasePathed, Equatable {
    case authenticated(accessToken: String)
    case unauthenticated
  }

  func testGetSubscript() {
    do {
      let auth = Authentication.authenticated(accessToken: "cafebeef")
      XCTAssertNil(auth[casePath: /Authentication.unauthenticated])
      XCTAssertEqual(auth[casePath: /Authentication.authenticated], "cafebeef")
    }
    do {
      let auth = Authentication.unauthenticated
      XCTAssertNotNil(auth[casePath: /Authentication.unauthenticated])  // can't test == ()
      XCTAssertNil(auth[casePath: /Authentication.authenticated])
    }
  }

  func testSetSubscript() {
    do {
      var auth = Authentication.authenticated(accessToken: "")
      auth[casePath: /Authentication.authenticated] = "cafebeef"
      XCTAssertEqual(auth, .authenticated(accessToken: "cafebeef"))
    }
    do {
      var auth = Authentication.unauthenticated
      auth[casePath: /Authentication.authenticated] = "cafebeef"
      XCTAssertEqual(auth, .authenticated(accessToken: "cafebeef"))
    }
    do {
      var auth = Authentication.authenticated(accessToken: "")
      auth[casePath: /Authentication.unauthenticated] = ()
      XCTAssertEqual(auth, .unauthenticated)
    }
  }

}
