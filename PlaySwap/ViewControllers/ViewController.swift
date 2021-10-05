//
//  ViewController.swift
//  PlaySwap
//
//  Created by Jordan Wood on 10/4/21.
//

import UIKit
import AnimatedGradientView
import Combine
import SpotifyWebAPI
import WebKit
//import Spotif
class ViewController: UIViewController, WKNavigationDelegate {
    var iTunesImage = UIImageView()
    var emailField = UITextField()
    var passwordField = UITextField()
    var webView = WKWebView()
    var loginButton = UIButton()
    var spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowManager(
        clientId: "", clientSecret: ""
    ))
    private var cancellables: Set<AnyCancellable> = []
    var transferType = "spotify" //spotify or itunes
    override func viewDidLoad() {
        super.viewDidLoad()
        //Here I just make a massive fucking itunes png in the middle of the screen
        
//        iTunesImage = createImage(named: "itunes.png")
//        iTunesImage.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        
        //EXAMPLE GRADIENT VIEW (POSSIBLY FOR ITUNES LOGIN PAGE?)
//        let gradient = AnimatedGradientView(frame: view.bounds)
//        gradient.direction = .upLeft
//        gradient.colorStrings = [["#b632ea", "#ff6641"] ,["#ff6641", "#b632ea"], ["#00d3e3", "#406ff3"], ["#406ff3", "#b632ea", "#b632ea"], ["#b632ea", "#b632ea"]]
//        gradient.animationDuration = 12
//        gradient.startAnimating()
//        view.addSubview(gradient)
        
        self.view.backgroundColor = .black
        
        
        emailField = createTextField()
        styleTextField(field: emailField)
        emailField.frame = CGRect(x: 50, y: 200, width: UIScreen.main.bounds.width - 100, height: 50)
        emailField.placeholder = "Email"
        emailField.attributedPlaceholder = NSAttributedString(string: "Email",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)])
        emailField.keyboardType = .emailAddress
        
        passwordField = createTextField()
        styleTextField(field: passwordField)
        passwordField.frame = CGRect(x: 50, y: 280, width: UIScreen.main.bounds.width - 100, height: 50)
        passwordField.placeholder = "Email"
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)])
        passwordField.isSecureTextEntry = true
        
        loginButton = createButton()
        loginButton.backgroundColor = .white
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        loginButton.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        loginButton.layer.borderWidth = 1
        loginButton.alpha = 1
        loginButton.layer.cornerRadius = 5
        loginButton.frame = CGRect(x: 50, y: UIScreen.main.bounds.height - 100, width: UIScreen.main.bounds.width - 100, height: 50)
        loginButton.addTarget(self, action: #selector(logginPressed(_:)), for: .touchUpInside)
        //Looks for single or multiple taps.
             let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            //tap.cancelsTouchesInView = false

            view.addGestureRecognizer(tap)
        
        spotify = SpotifyAPI(
            authorizationManager: AuthorizationCodeFlowManager(
                clientId: getEnvironmentVar("CLIENT_ID") ?? "", clientSecret: getEnvironmentVar("CLIENT_SECRET") ?? ""
            )
        )
        //WE CAN USE THIS URL TO AUTHENTICATE USER
        webView.navigationDelegate = self
        view.addSubview(webView)
//        webView.
        webView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadSpotifyLogin()
        
//        SpotifyWebAPI.
    }
    func loadSpotifyLogin() {
        DispatchQueue.main.async {
            let authorizationURL = self.spotify.authorizationManager.makeAuthorizationURL(
                redirectURI: URL(string: "https://google.com")!,
                showDialog: false,
                scopes: [
                    .playlistModifyPrivate,
                    .userModifyPlaybackState,
                    .playlistReadCollaborative,
                    .userReadPlaybackPosition,
                    .userFollowModify
                ]
            )!
            if(authorizationURL.absoluteString.contains("spotify")) {
                self.webView.load(URLRequest(url: authorizationURL))
            }
        }
        
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
//        if(
        if ((webView.url?.absoluteString as! String).contains("google")) {
            print("* spotify redirect detected")
            webView.isHidden = true
            webView.alpha = 0
            spotify.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: webView.url!
            )
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("successfully authorized")
                    case .failure(let error):
                        if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                            print("The user denied the authorization request")
                        }
                        else {
                            print("couldn't authorize application: \(error)")
                            self.loadSpotifyLogin()
                        }
                }
            })
            .store(in: &cancellables)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        calculatingIndicatorView.stopAnimating()
        print("* webview loaded from url: \(webView.url?.absoluteString as! String)")
        if((webView.url?.absoluteString as! String).contains("spotify")) {
//            webView.fadeIn()
        } else if ((webView.url?.absoluteString as! String).contains("google")) {
            print("* spotify redirect detected")
            webView.isHidden = true
            webView.alpha = 0
        }
    }
//    func handleURL(_ url: URL) {
//
//            // **Always** validate URLs; they offer a potential attack vector into
//            // your app.
//            guard url.scheme == self.spotify.loginCallbackURL.scheme else {
//                print("not handling URL: unexpected scheme: '\(url)'")
//
//                return
//            }
//
//            print("received redirect from Spotify: '\(url)'")
//
//            // This property is used to display an activity indicator in `LoginView`
//            // indicating that the access and refresh tokens are being retrieved.
//            spotify.isRetrievingTokens = true
//
//            // Complete the authorization process by requesting the access and
//            // refresh tokens.
//            spotify.api.authorizationManager.requestAccessAndRefreshTokens(
//                redirectURIWithQuery: url,
//                // This value must be the same as the one used to create the
//                // authorization URL. Otherwise, an error will be thrown.
//                state: spotify.authorizationState
//            )
//            .receive(on: RunLoop.main)
//            .sink(receiveCompletion: { completion in
//                // Whether the request succeeded or not, we need to remove the
//                // activity indicator.
//                self.spotify.isRetrievingTokens = false
//
//                /*
//                 After the access and refresh tokens are retrieved,
//                 `SpotifyAPI.authorizationManagerDidChange` will emit a signal,
//                 causing `Spotify.authorizationManagerDidChange()` to be called,
//                 which will dismiss the loginView if the app was successfully
//                 authorized by setting the @Published `Spotify.isAuthorized`
//                 property to `true`.
//                 The only thing we need to do here is handle the error and show it
//                 to the user if one was received.
//                 */
//                if case .failure(let error) = completion {
//                    print("couldn't retrieve access and refresh tokens:\n\(error)")
//                    let alertTitle: String
//                    let alertMessage: String
//                    if let authError = error as? SpotifyAuthorizationError,
//                       authError.accessWasDenied {
//                        alertTitle = "You Denied The Authorization Request :("
//                        alertMessage = ""
//                    }
//                    else {
//                        alertTitle =
//                            "Couldn't Authorization With Your Account"
//                        alertMessage = error.localizedDescription
//                    }
//                    self.alert = AlertItem(
//                        title: alertTitle, message: alertMessage
//                    )
//                }
//            })
//            .store(in: &cancellables)
//
//            // MARK: IMPORTANT: generate a new value for the state parameter after
//            // MARK: each authorization request. This ensures an incoming redirect
//            // MARK: from Spotify was the result of a request made by this app, and
//            // MARK: and not an attacker.
//            self.spotify.authorizationState = String.randomURLSafe(length: 128)
//
//        }
    func getEnvironmentVar(_ name: String) -> String? {
        guard let rawValue = getenv(name) else { return nil }
        return String(utf8String: rawValue)
    }
    @objc func logginPressed(_ sender: UIButton) {
        print("login button pressed")
    }
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func styleTextField(field: UITextField) {
//        field.font = UIFont(name: "SF Pro Display", size: 10)
        field.textColor = .white
        field.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        field.layer.borderWidth = 1
        field.alpha = 1
        field.layer.cornerRadius = 5
        field.setRightPaddingPoints(20)
        field.setLeftPaddingPoints(20)
        
    }

}
class TriangleView : UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.beginPath()
        context.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: (rect.maxX / 2.0), y: rect.minY))
        context.closePath()

        context.setFillColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.60)
        context.fillPath()
    }
}
extension UIViewController {
    func createButton() -> UIButton {
        let newButton = UIButton()
        view.addSubview(newButton)
        return newButton
    }
    func createView() -> UIView {
        let newView = UIView()
        view.addSubview(newView)
        return newView
    }
    func createImage(named:String) -> UIImageView {
        let newImage = UIImageView()
        newImage.image = UIImage(named: named)
        view.addSubview(newImage)
        return newImage
    }
    func createTextField() -> UITextField {
        let textField = UITextField()
        view.addSubview(textField)
        return textField
    }
    func createLabel() -> UILabel {
        let newLabel = UILabel()
        view.addSubview(newLabel)
        return newLabel
    }
    
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
extension UIView {

    func fadeIn(_ duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
    }, completion: completion)  }

    func fadeOut(_ duration: TimeInterval = 0.5, delay: TimeInterval = 1.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.3
    }, completion: completion)
   }
}
