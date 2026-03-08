import Foundation
import FirebaseFunctions

// MARK: - Data Models

struct SalesforceAuthResult {
    let authorized: Bool
    let contactId: String?
}

struct SalesforceContactData {
    // Contact → UserProfile
    let firstName: String
    let lastName: String
    let jobTitle: String
    let bio: String
    let nationality: String
    let languages: [String]
    let phone: String
    let userType: String
    // Account → CompanyProfile
    let companyName: String
    let companyWebsite: String
    let companyCountry: String
    let companyCity: String
    let companyBio: String
    let companyVertical: String
    let companyIndustry: String
    let companyChapter: String
}

// MARK: - Protocol

protocol SalesforceRepositoryProtocol {
    func checkAuthorization(email: String) async throws -> SalesforceAuthResult
    func getContactData(contactId: String) async throws -> SalesforceContactData
    func checkAndFetchContact(email: String) async throws -> (SalesforceAuthResult, SalesforceContactData?)
    func checkUserExists(email: String) async throws -> (exists: Bool, userId: String?)
}

// MARK: - Implementation

final class SalesforceRepository: SalesforceRepositoryProtocol {
    
    private lazy var functions: Functions = {
        let f = Functions.functions(region: "europe-west1")
        return f
    }()
    
    // MARK: checkAuthorization
    
    func checkAuthorization(email: String) async throws -> SalesforceAuthResult {
        let callable = functions.httpsCallable("checkSalesforceAuthorization")
        
        let result = try await callable.call(["email": email])
        
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "SalesforceRepository", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response from Salesforce check."])
        }
        
        let authorized = data["authorized"] as? Bool ?? false
        let contactId = data["contactId"] as? String
        
        return SalesforceAuthResult(authorized: authorized, contactId: contactId)
    }
    
    // MARK: getContactData
    
    func getContactData(contactId: String) async throws -> SalesforceContactData {
        let callable = functions.httpsCallable("getSalesforceContactData")
        
        let result = try await callable.call(["contactId": contactId])
        
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "SalesforceRepository", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response from Salesforce contact data."])
        }
        
        let rawLanguages = data["languages"] as? [String] ?? []
        
        return SalesforceContactData(
            firstName:       data["firstName"]       as? String ?? "",
            lastName:        data["lastName"]        as? String ?? "",
            jobTitle:        data["jobTitle"]        as? String ?? "",
            bio:             data["bio"]             as? String ?? "",
            nationality:     data["nationality"]     as? String ?? "",
            languages:       rawLanguages,
            phone:           data["phone"]           as? String ?? "",
            userType:        data["userType"]        as? String ?? "",
            companyName:     data["companyName"]     as? String ?? "",
            companyWebsite:  data["companyWebsite"]  as? String ?? "",
            companyCountry:  data["companyCountry"]  as? String ?? "",
            companyCity:     data["companyCity"]     as? String ?? "",
            companyBio:      data["companyBio"]      as? String ?? "",
            companyVertical: data["companyVertical"] as? String ?? "",
            companyIndustry: data["companyIndustry"] as? String ?? "",
            companyChapter:  data["companyChapter"]  as? String ?? ""
        )
    }
    
    // MARK: checkAndFetchContact
    
    func checkAndFetchContact(email: String) async throws -> (SalesforceAuthResult, SalesforceContactData?) {
        let callable = functions.httpsCallable("checkAndFetchSalesforceContact")
        let result = try await callable.call(["email": email])
        
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "SalesforceRepository", code: -1, 
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response."])
        }
        
        let authorized = data["authorized"] as? Bool ?? false
        guard authorized else {
            return (SalesforceAuthResult(authorized: false, contactId: nil), nil)
        }
        
        let contactId = data["contactId"] as? String
        let authResult = SalesforceAuthResult(authorized: true, contactId: contactId)
        
        let rawLanguages = data["languages"] as? [String] ?? []
        let contactData = SalesforceContactData(
            firstName:       data["firstName"]       as? String ?? "",
            lastName:        data["lastName"]        as? String ?? "",
            jobTitle:        data["jobTitle"]        as? String ?? "",
            bio:             data["bio"]             as? String ?? "",
            nationality:     data["nationality"]     as? String ?? "",
            languages:       rawLanguages,
            phone:           data["phone"]           as? String ?? "",
            userType:        data["userType"]        as? String ?? "",
            companyName:     data["companyName"]     as? String ?? "",
            companyWebsite:  data["companyWebsite"]  as? String ?? "",
            companyCountry:  data["companyCountry"]  as? String ?? "",
            companyCity:     data["companyCity"]     as? String ?? "",
            companyBio:      data["companyBio"]      as? String ?? "",
            companyVertical: data["companyVertical"] as? String ?? "",
            companyIndustry: data["companyIndustry"] as? String ?? "",
            companyChapter:  data["companyChapter"]  as? String ?? ""
        )
        
        return (authResult, contactData)
    }
    
    // MARK: checkUserExists
    
    func checkUserExists(email: String) async throws -> (exists: Bool, userId: String?) {
        let callable = functions.httpsCallable("checkUserExists")
        let result = try await callable.call(["email": email])
        
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "SalesforceRepository", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response from checkUserExists."])
        }
        
        let exists = data["exists"] as? Bool ?? false
        let userId = data["userId"] as? String
        return (exists: exists, userId: userId)
    }
}
