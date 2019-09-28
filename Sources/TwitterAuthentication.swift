// Copyright 2019 PIRIKA Association
// Copyright 2019 PIRIKA Inc.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  TwitterAuthentication.swift
//

import UIKit
import OAuthSwift
import SafariServices
import AuthenticationServices

public class TwitterAuthentication: NSObject {
    
    public typealias CompletionHandler = (Result) -> ()
    
    public enum Result {
        case success(token: String, secret: String, screenName: String)
        case failed(error: Error?)
        case cancelled
    }
    
    private enum AuthorizationState {
        case initial
        case sso
        case browser
        case requestingToken
    }
    private enum AuthorizeResult {
        case success(url: URL)
        case failed(error: Error)
        case cancelled(error: Error?)
    }
    
    let callbackURL: URL
    let consumerKey: String
    let consumerSecret: String
    
    private var completionHandler: CompletionHandler?
    private var state: AuthorizationState = .initial
    private var authenticationSessionObject: Any?
    private var useSafariView = false
    
    private var oauth: OAuth1Swift?
    
    public init?(consumerKey: String, consumerSecret: String, callbackScheme: String, useSafariView: Bool = false) {
        guard let callbackURL = URL(string: "\(callbackScheme)://")
            else { return nil }
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackURL = callbackURL
        self.useSafariView = useSafariView
    }
    
    public func authenticate(completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
        openSSO { [weak self] result in
            guard let `self` = self else { return }
            if !result {
                self.openBrowser()
            }
        }
    }
    
    public func handleOpen(_ url: URL, options: [UIApplication.OpenURLOptionsKey:Any]) -> Bool {
        guard url.scheme == callbackURL.scheme,
            validateAcceptableSourceApp(options),
            state != .initial,
            state != .requestingToken
            else { return false }
        callbacked(.success(url: url))
        return true
    }
}

//------------------------------------------------------------------------------------------
// MARK: Flow Control
//------------------------------------------------------------------------------------------

private extension TwitterAuthentication {
    
    private func callbacked(_ authorizeResult: AuthorizeResult) {
        switch authorizeResult {
        case .success(let url):
            if case .sso = state {
                // SSO mode
                state = .requestingToken
                parseSSOCallback(url)
            }
            else if case .browser = state {
                // Browser mode
                state = .requestingToken
                OAuth1Swift.handle(url: url)
            }
            else {
                onFailed(error: nil)
            }
        case .cancelled(_):
            onCancelled()
            break
        case .failed(let error):
            onFailed(error: error)
            break
        }
    }
    
    func onCompleted(token: String, secret: String, screenName: String) {
        cleanupVisibleControllers()
        if let completion = completionHandler {
            completion(.success(token: token, secret: secret, screenName: screenName))
        }
        cleanup()
    }
    
    func onSessionStartFailed() {
        onFailed(error: nil)
    }
    
    func onFailed(error: Error?) {
        cleanupVisibleControllers()
        if let completion = completionHandler {
            completion(.failed(error: error))
        }
        cleanup()
    }
    
    func onCancelled() {
        cleanupVisibleControllers()
        if let completion = completionHandler {
            completion(.cancelled)
        }
        cleanup()
    }
    
    func cleanupVisibleControllers() {
        if let safariViewController = authenticationSessionObject as? SFSafariViewController {
            safariViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func cleanup() {
        authenticationSessionObject = nil
        oauth?.cancel()
        oauth = nil
        state = .initial
    }
}

//------------------------------------------------------------------------------------------
// MARK: SSO
//------------------------------------------------------------------------------------------

private extension TwitterAuthentication {
    
    func openSSO(completionHandler: @escaping (Bool) -> ())  {
        if useSafariView {
            completionHandler(false)
            return
        }
        guard let url = URL(string: "twitterauth://authorize?consumer_key=\(consumerKey)&consumer_secret=\(consumerSecret)&oauth_callback=\(callbackURL.scheme ?? "")")
            else { return completionHandler(false) }
        UIApplication.shared.open(url, options: [:], completionHandler: { [weak self] in
            if $0 {
                guard let `self` = self else { return }
                self.state = .sso
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.willEnterForeground(_:)),
                                                       name: UIApplication.willEnterForegroundNotification,
                                                       object: nil)
            }
            completionHandler($0)
        })
    }
    
    private func parseSSOCallback(_ url: URL) {
        guard let query = url.host,
            let components = NSURLComponents(string: "http://localhost/?\(query)"),
            let items = components.queryItems
            else { return onCancelled() }
        
        let dict = items.reduce([String:String]()) { (result, item) -> [String:String] in
            if let value = item.value {
                var r = result
                r[item.name] = value
                return r
            }
            return result
        }
        
        guard let token = dict["token"],
            let secret = dict["secret"],
            let screenName = dict["username"]
            else { return onFailed(error: nil) }
        
        onCompleted(token: token, secret: secret, screenName: screenName)
    }
    
    @objc func willEnterForeground(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if case .sso = self.state {
                self.onCancelled()
            }
        }
    }
    
    func validateAcceptableSourceApp(_ options: [UIApplication.OpenURLOptionsKey:Any]) -> Bool {
        guard let source = options[.sourceApplication] as? String else {
            return false
        }
        return source.hasPrefix("com.twitter") || source.hasPrefix("com.atebits") // Twitter App
                || source.hasPrefix("com.apple.SafariViewService") // SFSafariViewController
    }
}

//------------------------------------------------------------------------------------------
// MARK: Browser Authentication
//------------------------------------------------------------------------------------------

extension TwitterAuthentication: OAuthSwiftURLHandlerType {
    
    func openBrowser() {
        
        let oauth = OAuth1Swift(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
        oauth.authorizeURLHandler = self
        self.oauth = oauth
        self.state = .browser
        
        let _ = oauth.authorize(
            withCallbackURL: callbackURL,
            success: { [weak self] credential, response, parameters in
                guard let `self` = self else { return }
                // complete
                let token = credential.oauthToken
                let secret = credential.oauthTokenSecret
                let screenName = (parameters["screen_name"] as? String) ?? ""
                self.onCompleted(token: token, secret: secret, screenName: screenName)
            },
            failure: { [weak self] error in
                self?.onFailed(error: error)
            }
        )
    }
    
    public func handle(_ url: URL) {
        if #available(iOS 12, *) {
            // ASWebAuthenticationSession
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURL.scheme, completionHandler: { [weak self] (url, error) in
                guard let `self` = self else { return }
                if let callbackedURL = url {
                    self.callbacked(.success(url: callbackedURL))
                }
                guard let err = error else { return }
                if case ASWebAuthenticationSessionError.canceledLogin = err {
                    self.callbacked(.cancelled(error: err))
                }
                else {
                    self.callbacked(.failed(error: err))
                }
            })
            if #available(iOS 13, *) {
                session.presentationContextProvider = self
            }
            if !session.start() {
                return onSessionStartFailed()
            }
            authenticationSessionObject = session
        }
        else if #available(iOS 11, *) {
            // SFAuthenticationSession
            let session = SFAuthenticationSession(url: url, callbackURLScheme: callbackURL.scheme) { [weak self] (url, error) in
                guard let `self` = self else { return }
                if let callbackedURL = url {
                    self.callbacked(.success(url: callbackedURL))
                }
                guard let err = error else { return }
                if case SFAuthenticationError.canceledLogin = err {
                    self.callbacked(.cancelled(error: err))
                }
                else {
                    self.callbacked(.failed(error: err))
                }
            }
            if !session.start() {
                return onSessionStartFailed()
            }
            authenticationSessionObject = session
        }
        else {
            // SFSafariViewController
            let session = SFSafariViewController(url: url)
            session.delegate = self
            authenticationSessionObject = session
            guard let window = UIApplication.shared.keyWindow,
                let viewController = window.rootViewController
                else { return onSessionStartFailed() }
            viewController.present(session, animated: true, completion: nil)
        }
    }
}

@available(iOS 13.0, *)
extension TwitterAuthentication: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.keyWindow else { fatalError("keyWindow not detected.") }
        return window
    }
}

extension TwitterAuthentication: SFSafariViewControllerDelegate {
    
    @objc public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guard state == .browser else { return }
        callbacked(.cancelled(error: nil))
    }
}
