@testable import App
import XCTest
import XCTVapor


final class RolesUpdateActionTests: XCTestCase {

    func testCorrectRoleShouldBeUpdatedBySuperUser() throws {

        // Arrange.
        let user = try User.create(userName: "brucelee",
                                   email: "brucelee@testemail.com",
                                   name: "Bruce Lee")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()
        let role = try Role.create(name: "Seller", code: "seller", description: "Seller")
        let roleToUpdate = RoleDto(id: role.id, role: "Junior serller", code: "junior-seller", description: "Junior seller", hasSuperPrivileges: false, isDefault: true)

        // Act.
        let response = try SharedApplication.application().sendRequest(
            as: .user(userName: "brucelee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            body: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(response.status, HTTPResponseStatus.ok, "Response http status code should be ok (200).")
        guard let updatedRole = try? Role.get(role: "Junior serller") else {
            XCTAssert(true, "Role was not found")
            return
        }

        XCTAssertEqual(updatedRole.id, roleToUpdate.id, "Role id should be correct.")
        XCTAssertEqual(updatedRole.role, roleToUpdate.role, "Role name should be correct.")
        XCTAssertEqual(updatedRole.code, roleToUpdate.code, "Role code should be correct.")
        XCTAssertEqual(updatedRole.description, roleToUpdate.description, "Role description should be correct.")
        XCTAssertEqual(updatedRole.hasSuperPrivileges, roleToUpdate.hasSuperPrivileges, "Role super privileges should be correct.")
        XCTAssertEqual(updatedRole.isDefault, roleToUpdate.isDefault, "Role default should be correct.")
    }

    func testRoleShouldNotBeUpdatedIfUserIsNotSuperUser() throws {

        // Arrange.
        _ = try User.create(userName: "georgelee",
                            email: "georgelee@testemail.com",
                            name: "Geaorge Lee")
        let role = try Role.create(name: "Senior seller", code: "senior-seller", description: "Senior seller")
        let roleToUpdate = RoleDto(id: role.id, role: "Junior serller", code: "junior-seller", description: "Junior seller", hasSuperPrivileges: false, isDefault: true)

        // Act.
        let response = try SharedApplication.application().sendRequest(
            as: .user(userName: "georgelee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            body: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(response.status, HTTPResponseStatus.forbidden, "Response http status code should be forbidden (403).")
    }

    func testRoleShouldNotBeUpdatedIfRoleWithSameCodeExists() throws {

        // Arrange.
        let user = try User.create(userName: "samlee",
                                   email: "samlee@testemail.com",
                                   name: "Sam Lee")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()
        let role = try Role.create(name: "Marketer", code: "marketer", description: "marketer")
        let roleToUpdate = RoleDto(id: role.id, role: "Administrator", code: "administrator", description: "Administrator", hasSuperPrivileges: false, isDefault: true)

        // Act.
        let errorResponse = try SharedApplication.application().getErrorResponse(
            as: .user(userName: "samlee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            data: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(errorResponse.status, HTTPResponseStatus.badRequest, "Response http status code should be bad request (400).")
        XCTAssertEqual(errorResponse.error.code, "roleWithCodeExists", "Error code should be equal 'roleWithCodeExists'.")
    }

    func testRoleShouldNotBeUpdatedIfCodeIsTooLong() throws {

        // Arrange.
        let user = try User.create(userName: "wandalee",
                                   email: "wandalee@testemail.com",
                                   name: "Wanda Lee")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()
        let role = try Role.create(name: "Manager1", code: "manager1", description: "Manager")
        let roleToUpdate = RoleDto(id: role.id, role: "Senior manager", code: "123456789012345678901", description: "Senior manager", hasSuperPrivileges: false, isDefault: true)

        // Act.
        let errorResponse = try SharedApplication.application().getErrorResponse(
            as: .user(userName: "wandalee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            data: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(errorResponse.status, HTTPResponseStatus.badRequest, "Response http status code should be bad request (400).")
        XCTAssertEqual(errorResponse.error.code, "validationError", "Error code should be equal 'validationError'.")
        XCTAssertEqual(errorResponse.error.reason, "Validation errors occurs.")
        XCTAssertEqual(errorResponse.error.failures?.getFailure("code"), "is greater than maximum of 20 character(s)")
    }

    func testRoleShouldNotBeUpdatedIfNameIsTooLong() throws {

        // Arrange.
        let user = try User.create(userName: "monikalee",
                                   email: "monikalee@testemail.com",
                                   name: "Monika Lee")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()
        let role = try Role.create(name: "Manager2", code: "manager2", description: "Manager")
        let roleToUpdate = RoleDto(id: role.id,
                                   role: "123456789012345678901234567890123456789012345678901",
                                   code: "senior-manager",
                                   description: "Senior manager",
                                   hasSuperPrivileges: false,
                                   isDefault: true)

        // Act.
        let errorResponse = try SharedApplication.application().getErrorResponse(
            as: .user(userName: "monikalee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            data: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(errorResponse.status, HTTPResponseStatus.badRequest, "Response http status code should be bad request (400).")
        XCTAssertEqual(errorResponse.error.code, "validationError", "Error code should be equal 'validationError'.")
        XCTAssertEqual(errorResponse.error.reason, "Validation errors occurs.")
        XCTAssertEqual(errorResponse.error.failures?.getFailure("role"), "is greater than maximum of 50 character(s)")
    }

    func testRoleShouldNotBeUpdatedIfDescriptionIsTooLong() throws {

        // Arrange.
        let user = try User.create(userName: "annalee",
                                   email: "annalee@testemail.com",
                                   name: "Anna Lee")
        let administrator = try Role.get(role: "Administrator")
        try user.$roles.attach(administrator, on: SharedApplication.application().db).wait()
        let role = try Role.create(name: "Manager3", code: "manager3", description: "Manager")
        let roleToUpdate = RoleDto(id: role.id,
                                   role: "Senior manager",
                                   code: "senior-manager",
                                   description: "12345678901234567890123456789012345678901234567890" +
                                                "12345678901234567890123456789012345678901234567890" +
                                                "12345678901234567890123456789012345678901234567890" +
                                                "123456789012345678901234567890123456789012345678901",
                                   hasSuperPrivileges: false,
                                   isDefault: true)

        // Act.
        let errorResponse = try SharedApplication.application().getErrorResponse(
            as: .user(userName: "annalee", password: "p@ssword"),
            to: "/roles/\(role.id?.uuidString ?? "")",
            method: .PUT,
            data: roleToUpdate
        )

        // Assert.
        XCTAssertEqual(errorResponse.status, HTTPResponseStatus.badRequest, "Response http status code should be bad request (400).")
        XCTAssertEqual(errorResponse.error.code, "validationError", "Error code should be equal 'validationError'.")
        XCTAssertEqual(errorResponse.error.reason, "Validation errors occurs.")
        XCTAssertEqual(errorResponse.error.failures?.getFailure("description"), "is greater than maximum of 200 character(s) and is not null")
    }

    static let allTests = [
        ("testCorrectRoleShouldBeUpdatedBySuperUser", testCorrectRoleShouldBeUpdatedBySuperUser),
        ("testRoleShouldNotBeUpdatedIfUserIsNotSuperUser", testRoleShouldNotBeUpdatedIfUserIsNotSuperUser),
        ("testRoleShouldNotBeUpdatedIfRoleWithSameCodeExists", testRoleShouldNotBeUpdatedIfRoleWithSameCodeExists),
        ("testRoleShouldNotBeUpdatedIfCodeIsTooLong", testRoleShouldNotBeUpdatedIfCodeIsTooLong),
        ("testRoleShouldNotBeUpdatedIfNameIsTooLong", testRoleShouldNotBeUpdatedIfNameIsTooLong),
        ("testRoleShouldNotBeUpdatedIfDescriptionIsTooLong", testRoleShouldNotBeUpdatedIfDescriptionIsTooLong)
    ]
}

