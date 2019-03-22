//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import XCTest

class MockConfiguration: GeoOffersSDKConfiguration {
    func refresh() {}

    var mainAppUsesFirebase: Bool = false
    let registrationCode: String = "123456"
    let authToken: String = UUID().uuidString
    let deviceID: String = GeoOffersSDKUserDefaults.shared.deviceID
    var selectedCategoryTabBackgroundColor: String = "FF0000"
    var timezone: String = TimeZone.current.identifier
    var apiURL: String = ""
    var offerDetailsURL: String = "https://localhost"
    var clientID: Int?
    var pushToken: String?
    var pendingPushTokenRegistration: String?
    public let minimumRefreshWaitTime: Double = 0
    public let minimumRefreshDistance: Double = 0
}

class GeoOffersAPIServiceTests: XCTestCase {
    private let testRegistrationCode = "123456"
    private let testAuthToken = UUID().uuidString
    private let latitude: Double = 54.2
    private let longitude: Double = -0.25
    private let clientID = 40

    private var service: GeoOffersAPIService!
    private var session = MockURLSession()
    private var session2 = MockURLSession()

    private let mockConfig = MockConfiguration()
    private var serviceWithMockConfig: GeoOffersAPIService!

    override func setUp() {
        let configuration = GeoOffersConfigurationDefault(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        service = GeoOffersAPIServiceDefault(configuration: configuration, session: session)
        session.testDelegate = service as? URLSessionDelegate
        serviceWithMockConfig = GeoOffersAPIServiceDefault(configuration: mockConfig, session: session2)
        session2.testDelegate = serviceWithMockConfig as? URLSessionDelegate
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_pollForNearbyOffers() {
        let expectation = self.expectation(description: "Wait for response")
        service.pollForNearbyOffers(latitude: latitude, longitude: longitude) { response in
            expectation.fulfill()
            switch response {
            case .failure, .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_pollForNearbyOffers_invalid_url() {
        let expectation = self.expectation(description: "Wait for response")
        serviceWithMockConfig.pollForNearbyOffers(latitude: latitude, longitude: longitude) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! GeoOffersAPIErrors, GeoOffersAPIErrors.failedToBuildURL)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_countdownsStarted() {
        let expectation = self.expectation(description: "Wait for response")
        service.countdownsStarted(hashes: []) { response in
            expectation.fulfill()
            guard case .success = response else {
                XCTFail("Invalid response")
                return
            }
            XCTAssertTrue(true)
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_countdownsStarted_invalid_url() {
        let expectation = self.expectation(description: "Wait for response")
        serviceWithMockConfig.countdownsStarted(hashes: []) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! GeoOffersAPIErrors, GeoOffersAPIErrors.failedToBuildURL)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_countdownsStarted_with_error() {
        session.responseError = TestErrors.updatePushFailed
        let expectation = self.expectation(description: "Wait for response")
        service.countdownsStarted(hashes: []) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! TestErrors, TestErrors.updatePushFailed)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_register() {
        let expectation = self.expectation(description: "Wait for response")
        service.register(pushToken: UUID().uuidString, latitude: latitude, longitude: longitude, clientID: clientID) { response in
            expectation.fulfill()
            switch response {
            case .success:
                XCTAssertTrue(true)
            case .dataTask, .failure:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_register_invalid_url() {
        let expectation = self.expectation(description: "Wait for response")
        serviceWithMockConfig.register(pushToken: UUID().uuidString, latitude: latitude, longitude: longitude, clientID: clientID) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! GeoOffersAPIErrors, GeoOffersAPIErrors.failedToBuildURL)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_register_with_error() {
        session.responseError = TestErrors.registerFailed
        let expectation = self.expectation(description: "Wait for response")
        service.register(pushToken: UUID().uuidString, latitude: latitude, longitude: longitude, clientID: clientID) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! TestErrors, TestErrors.registerFailed)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_update() {
        service.update(pushToken: UUID().uuidString, with: UUID().uuidString, completionHandler: nil)
        let expectation = self.expectation(description: "Wait for response")
        service.update(pushToken: UUID().uuidString, with: UUID().uuidString) { response in
            expectation.fulfill()
            switch response {
            case .success:
                XCTAssertTrue(true)
            case .dataTask, .failure:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_update_invalid_url() {
        service.update(pushToken: UUID().uuidString, with: UUID().uuidString, completionHandler: nil)
        let expectation = self.expectation(description: "Wait for response")
        serviceWithMockConfig.update(pushToken: UUID().uuidString, with: UUID().uuidString) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! GeoOffersAPIErrors, GeoOffersAPIErrors.failedToBuildURL)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_update_with_error() {
        session.responseError = TestErrors.updatePushFailed
        service.update(pushToken: UUID().uuidString, with: UUID().uuidString, completionHandler: nil)
        let expectation = self.expectation(description: "Wait for response")
        service.update(pushToken: UUID().uuidString, with: UUID().uuidString) { response in
            expectation.fulfill()
            switch response {
            case let .failure(error):
                XCTAssertEqual(error as! TestErrors, TestErrors.updatePushFailed)
            case .success:
                XCTFail("Should be no error")
            case let .dataTask(data):
                XCTAssert(data == nil, "Should be no data")
            }
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_deleteOffer() {
        let expectation = self.expectation(description: "Wait for response")
        session.testExpectation = expectation
        service.delete(scheduleID: 123)
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        XCTAssertTrue(session.taskComplete)
        XCTAssertFalse(session.taskCompleteWithError)
    }

    func test_deleteOffer_invalid_url() {
        serviceWithMockConfig.delete(scheduleID: 123)
        XCTAssertFalse(session.taskComplete)
        XCTAssertFalse(session.taskCompleteWithError)
    }

    func test_deleteOffer_with_error() {
        session.responseError = TestErrors.deleteOfferFailed
        let expectation = self.expectation(description: "Wait for response")
        session.testExpectation = expectation
        service.delete(scheduleID: 123)
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        XCTAssertTrue(session.taskComplete)
        XCTAssertTrue(session.taskCompleteWithError)
    }

    func test_tracking() {
        let trackingEvent = GeoOffersTrackingEvent(type: .geoFenceEntry, timestamp: Date().timeIntervalSinceReferenceDate * 1000, scheduleDeviceID: "ABC123", scheduleID: 123, latitude: latitude, longitude: longitude)

        let expectation = self.expectation(description: "Wait for response")
        session.testExpectation = expectation
        service.track(event: trackingEvent)
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        XCTAssertTrue(session.taskComplete)
        XCTAssertFalse(session.taskCompleteWithError)
    }

    func test_tracking_invalid_url() {
        let trackingEvent = GeoOffersTrackingEvent(type: .geoFenceEntry, timestamp: Date().timeIntervalSinceReferenceDate * 1000, scheduleDeviceID: "ABC123", scheduleID: 123, latitude: latitude, longitude: longitude)

        serviceWithMockConfig.track(event: trackingEvent)
        XCTAssertFalse(session.taskComplete)
        XCTAssertFalse(session.taskCompleteWithError) }

    func test_tracking_with_error() {
        session.responseError = TestErrors.trackEventFailed
        let trackingEvent = GeoOffersTrackingEvent(type: .geoFenceEntry, timestamp: Date().timeIntervalSinceReferenceDate * 1000, scheduleDeviceID: "ABC123", scheduleID: 123, latitude: latitude, longitude: longitude)

        let expectation = self.expectation(description: "Wait for response")
        session.testExpectation = expectation
        service.track(event: trackingEvent)
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        XCTAssertTrue(session.taskComplete)
        XCTAssertTrue(session.taskCompleteWithError)
    }
}