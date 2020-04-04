@testable import App
import XCTest
import XCTVapor

final class RolesListActionTests: XCTestCase {

    func testListOfRolesShouldBeReturnedForSuperUser() throws {

        // Arrange.
        let user = try User.create(userName: "robinorange",
                                   email: "robinorange@testemail.com",
                                   name: "Robin Orange")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()

        // Act.
        let roles = try SharedApplication.application().getResponse(
            as: .user(userName: "robinorange", password: "p@ssword"),
            to: "/roles",
            method: .GET,
            decodeTo: [RoleDto].self
        )

        // Assert.
        XCTAssert(roles.count > 0, "Role list was returned.")
    }

    func testListOfRolesShouldNotBeReturnedForNotSuperUser() throws {

        // Arrange.
        _ = try User.create(userName: "wictororange",
                            email: "robinorange@testemail.com",
                            name: "Wictor Orange")

        // Act.
        let response = try SharedApplication.application().sendRequest(
            as: .user(userName: "wictororange", password: "p@ssword"),
            to: "/roles",
            method: .GET
        )

        // Assert.
        XCTAssertEqual(response.status, HTTPResponseStatus.forbidden, "Response http status code should be bad request (400).")
    }

    static let allTests = [
        ("testListOfRolesShouldBeReturnedForSuperUser", testListOfRolesShouldBeReturnedForSuperUser),
        ("testListOfRolesShouldNotBeReturnedForNotSuperUser", testListOfRolesShouldNotBeReturnedForNotSuperUser)
    ]
}
