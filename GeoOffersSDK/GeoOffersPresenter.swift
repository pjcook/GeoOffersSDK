//  Copyright © 2019 Zappit. All rights reserved.

import UIKit
import WebKit

protocol GeoOffersPresenterProtocol: class {
    func buildOfferListViewController(service: GeoOffersSDKServiceProtocol?) -> UIViewController
    func refreshOfferListViewController(_ viewController: GeoOffersViewController)
    func buildCouponViewController(scheduleID: ScheduleID) -> UIViewController
    var viewControllerDelegate: GeoOffersViewControllerDelegate? { get set }
}

class GeoOffersPresenter: GeoOffersPresenterProtocol {
    private let configuration: GeoOffersInternalConfiguration
    private let locationService: GeoOffersLocationService
    private let cacheService: GeoOffersWebViewCache
    private let trackingCache: GeoOffersTrackingCache
    private let apiService: GeoOffersAPIServiceProtocol
    
    weak var viewControllerDelegate: GeoOffersViewControllerDelegate?

    init(
        configuration: GeoOffersInternalConfiguration,
        locationService: GeoOffersLocationService,
        cacheService: GeoOffersWebViewCache,
        trackingCache: GeoOffersTrackingCache,
        apiService: GeoOffersAPIServiceProtocol
    ) {
        self.configuration = configuration
        self.locationService = locationService
        self.cacheService = cacheService
        self.trackingCache = trackingCache
        self.apiService = apiService
    }

    private func offersURL() -> URL? {
        let baseURL = Bundle(for: GeoOffersPresenter.self).url(forResource: "offerslist", withExtension: "html")
        return baseURL
    }

    private func couponURL() -> URL? {
        let baseURL = Bundle(for: GeoOffersPresenter.self).url(forResource: "coupon", withExtension: "html")
        return baseURL
    }

    func buildOfferListViewController(service: GeoOffersSDKServiceProtocol?) -> UIViewController {
        let storyboard = UIStoryboard(name: "GeoOffersSDK", bundle: Bundle(for: GeoOffersPresenter.self))
        guard let vc = storyboard.instantiateInitialViewController() as? GeoOffersViewController
        else {
            geoOffersLog("Failed to buildOfferListViewController")
            return UIViewController()
        }

        vc.presenter = self
        vc.delegate = viewControllerDelegate
        vc.service = service

        if var service = service {
            service.offersUpdatedDelegate = vc
        }

        refreshOfferListViewController(vc)
        return vc
    }

    func refreshOfferListViewController(_ viewController: GeoOffersViewController) {
        guard let url = offersURL() else { return }
        let jsonData = cacheService.buildListingRequestJson()
        guard jsonData != "{}" else {
            viewController.noOffers()
            return
        }

        let queryString = buildOfferListQuerystring(configuration: configuration, locationService: locationService)
        let alreadyDeliveredOfferData = cacheService.buildAlreadyDeliveredOfferJson()
        let deliveredIdsAndTimestamps = cacheService.buildAlreadyDeliveredOfferIdTimestampJson()
        let javascript = buildJavascriptForWebView(listingData: jsonData, couponData: "", authToken: configuration.authToken, tabBackgroundColor: configuration.selectedCategoryTabBackgroundColor, alreadyDeliveredOfferData: alreadyDeliveredOfferData, deliveredIdsAndTimestamps: deliveredIdsAndTimestamps)
        viewController.loadRequest(url: url, javascript: javascript, querystring: queryString)
    }

    func buildCouponViewController(scheduleID: ScheduleID) -> UIViewController {
        let storyboard = UIStoryboard(name: "GeoOffersSDK", bundle: Bundle(for: GeoOffersPresenter.self))
        guard let url = couponURL(),
            let vc = storyboard.instantiateInitialViewController() as? GeoOffersViewController
        else {
            geoOffersLog("Failed to buildOfferListViewController")
            return UIViewController()
        }
        let offer = cacheService.offer(scheduleID: scheduleID)
        let jsonData = cacheService.buildCouponRequestJson(offer: offer)
        vc.presenter = self
        vc.delegate = viewControllerDelegate
        let javascript = buildJavascriptForWebView(listingData: "", couponData: jsonData, authToken: configuration.authToken, tabBackgroundColor: configuration.selectedCategoryTabBackgroundColor, alreadyDeliveredOfferData: "", deliveredIdsAndTimestamps: "")
        let queryString = buildCouponQuerystring(configuration: configuration, locationService: locationService)
        vc.loadRequest(url: url, javascript: javascript, querystring: queryString)
        trackCouponOpened(scheduleID, offer: offer)
        return vc
    }
    
    private func trackCouponOpened(_ scheduleID: ScheduleID, offer: GeoOffersOffer?) {
        let location = locationService.latestLocation
        let trackingEvent = GeoOffersTrackingEvent(type: .couponOpened, timestamp: Date().unixTimeIntervalSince1970, scheduleDeviceID: offer?.deviceUid ?? "", scheduleID: scheduleID, latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0, clientCouponHash: offer?.clientCouponHash)
        trackingCache.add(trackingEvent)
        apiService.checkForPendingTrackingEvents()
    }
}

extension GeoOffersPresenter {
    func buildOfferListQuerystring(configuration: GeoOffersInternalConfiguration, locationService: GeoOffersLocationService) -> String {
        let registrationCode = configuration.registrationCode
        var latitude = ""
        var longitude = ""
        if let location = locationService.latestLocation {
            latitude = String(location.latitude)
            longitude = String(location.longitude)
        }
        let deviceID = configuration.deviceID
        let queryString = "#\(registrationCode),\(latitude),\(longitude),\(deviceID)"
        return queryString
    }

    func buildCouponQuerystring(configuration: GeoOffersInternalConfiguration, locationService: GeoOffersLocationService) -> String {
        var latitude = ""
        var longitude = ""
        if let location = locationService.latestLocation {
            latitude = String(location.latitude)
            longitude = String(location.longitude)
        }
        let timezone = configuration.timezone.urlEncode() ?? ""
        let queryString = "#\(latitude),\(longitude),\(timezone)"
        return queryString
    }

    func buildJavascriptForWebView(listingData: String, couponData: String, authToken: String, tabBackgroundColor: String, alreadyDeliveredOfferData: String, deliveredIdsAndTimestamps: String) -> String {
        guard let url = Bundle(for: GeoOffersPresenter.self).url(forResource: "ListingJSTemplate", withExtension: "js") else { return "" }
        do {
            let template = try String(contentsOf: url, encoding: .utf8)
            return template
                .replacingOccurrences(of: "<listingData>", with: listingData)
                .replacingOccurrences(of: "<couponData>", with: couponData)
                .replacingOccurrences(of: "<authToken>", with: authToken)
                .replacingOccurrences(of: "<tabBackgroundColor>", with: tabBackgroundColor)
                .replacingOccurrences(of: "<AlreadyDeliveredOfferData>", with: alreadyDeliveredOfferData)
                .replacingOccurrences(of: "<deliveredIdsAndTimestamps>", with: deliveredIdsAndTimestamps)
        } catch {
            geoOffersLog("\(error)")
            return ""
        }
    }
}
