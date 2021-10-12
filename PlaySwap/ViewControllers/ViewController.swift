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
import AVKit
import AVFoundation
import NewYorkAlert
class searchTableViewCell: UITableViewCell {
    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var playlistCreaterLabel: UILabel!
    
    @IBOutlet weak var playlistCoverPhoto: UIImageView!
    var playlistItem: Playlist<PlaylistItemsReference>!
}
class ViewController: UIViewController, WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var emailField = UITextField()
    var passwordField = UITextField()
    var webView = WKWebView()
    var loginButton = UIButton()
    
    //LOGIN PAGE PART 1
    var chooseService = UILabel()
    var continueButton = UIButton()
    var iTunesImage = UIImageView()
    var spotifyImage = UIImageView()
    var iTunesButton = UIButton()
    var spotifyButton = UIButton()
    
    //SEARCH PAGE
    var searchBar = UITextField()
    @IBOutlet weak var searchResultsViewController: UITableView!
    
    var backButton = UIButton()
    var spotifySearchResults : [Playlist<PlaylistItemsReference>] = []
    
    var spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowManager(
        clientId: "", clientSecret: ""
    ))
    var playerLayer = AVPlayerLayer()
    
    var transferringFrom = ""
    
    var songQueue: [SpotifyURIConvertible] = []
    private var cancellables: Set<AnyCancellable> = []
    var transferType = "spotify" //spotify or itunes
    var currentStep = "choose_service"
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
        
//        self.view.backgroundColor = hexStringToUIColor(hex: "#f0f3f4")
        
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
//        searchResultsTableView.frame = CG
        //SPOTIFY SHIT (gets environment variables)
        spotify = SpotifyAPI(
            authorizationManager: AuthorizationCodeFlowManager(
                clientId: UIApplication.clientId ?? "", clientSecret: UIApplication.clientSecret ?? ""
            )
        )
        searchResultsViewController.delegate = self
        searchResultsViewController.dataSource = self
        self.view.bringSubviewToFront(searchResultsViewController)
        //JUST MAKING WEBVIEW VISIBLE
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        playVideo(from: "Mobile_Web_BG.m4v")
        
        //ACTUALLY LOAD AUTHENTICATION URL & LOAD INTO APP
//        loadSpotifyLogin()
//        searchBar.delegate = self
//        searchBar.inputDelegate = self
        searchResultsViewController.rowHeight = 60

    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        print("detected change in text field -- searching")
        searchSpotify(query: textField.text ?? "", type: .playlist)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spotifySearchResults.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! searchTableViewCell
//        tableView.deselectRow(at: indexPath, animated: true)
        print(spotifySearchResults[indexPath.row])
        print("internal uri: \(spotifySearchResults[indexPath.row].uri)")
        getPlayListItemsFrom(uri: spotifySearchResults[indexPath.row].uri, offset: 0)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! searchTableViewCell
        
        cell.playlistCoverPhoto.image = nil
        //SET LABELS AND SUCH
        if(spotifySearchResults.count > indexPath.row) {
            cell.playlistNameLabel.text = (spotifySearchResults[indexPath.row].name ?? "") as! String
            cell.playlistCreaterLabel.text = (spotifySearchResults[indexPath.row].owner?.displayName ?? "") as! String
            if(spotifySearchResults[indexPath.row].images.isNotEmpty) {
                cell.playlistCoverPhoto.downloaded(from: spotifySearchResults[indexPath.row].images[0].url)
            } else {
                //playlist doesnt have image -- show placeholder
                cell.playlistCoverPhoto.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
            }
        }
        
//        cell.playlistItem = spotifySearchResults[indexPath.row]
        cell.selectionStyle = .none
        
        return cell
    }
    private func playVideo(from file:String) {
        let file = file.components(separatedBy: ".")

        guard let path = Bundle.main.path(forResource: file[0], ofType:file[1]) else {
            debugPrint( "\(file.joined(separator: ".")) not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        playerLayer.videoGravity = .resizeAspectFill
//        playerLayer.repeatCount = .infinity
        player.volume = 0
        self.view.layer.addSublayer(playerLayer)
        loopVideo(videoPlayer: player)
//        view.layer.sendSubviewToBack(playerLayer.)
        player.play()
        addLoginPage1Elements()
    }
    func addLoginPage1Elements() {
        
        //CoNTINUE BUTTON AT BOTTOM
        continueButton = createButton()
        iTunesButton.fadeIn()
        spotifyButton.fadeIn()
        continueButton.alpha = 0
        continueButton.setTitle("continue", for: .normal)
        continueButton.backgroundColor = hexStringToUIColor(hex: "#f0f3f4")
        continueButton.layer.borderColor = hexStringToUIColor(hex: "#c2c2c2").cgColor
        continueButton.layer.borderWidth = 1
//        continueButton.alpha = 1
        continueButton.layer.cornerRadius = 5
        continueButton.frame = CGRect(x: 50, y: UIScreen.main.bounds.height - 100, width: UIScreen.main.bounds.width - 100, height: 50)
        continueButton.fadeIn()
        continueButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 16)
        continueButton.addTarget(self, action: #selector(continuePressed(_:)), for: .touchUpInside)
        continueButton.setTitleColor(hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
        continueButton.dropShadow()
        
        //ITUNES AND SPOTIFY IMAGES
        iTunesImage = createImage(named: "itunes.png")
        iTunesImage.frame = CGRect(x: (UIScreen.main.bounds.width/2)-32 - 75,y: 200,width: 64, height: 64)
        spotifyImage = createImage(named: "spotify.png")
        spotifyImage.alpha = 0
        spotifyImage.fadeIn()
        spotifyImage.frame = CGRect(x: (UIScreen.main.bounds.width/2)-32 + 75,y: 200,width: 64, height: 64)
        iTunesImage.contentMode = .scaleAspectFill
        
        //THESE ARE BUTTONS THAT JUST LAY ON TOP OF THE IMAGES SO WE CAN DETECT PRESSES
        iTunesButton = createButton()
        iTunesButton.setTitle("", for: .normal)
        iTunesButton.frame = iTunesImage.frame
        spotifyButton = createButton()
        spotifyButton.setTitle("", for: .normal)
        spotifyButton.frame = spotifyImage.frame
        iTunesButton.addTarget(self, action: #selector(iTunesPressed(_:)), for: .touchUpInside)
        spotifyButton.addTarget(self, action: #selector(spotifyPressed(_:)), for: .touchUpInside)
        
        
//        UILABEL ABOVE IMAGES
        chooseService = createLabel()
        chooseService.alpha = 0
        
        chooseService.font = UIFont(name: "HypermarketW00-Regular", size: 16)
        chooseService.text = "CHOOSE THE SERVICE YOU WANT TO TRANSFER TO".lowercased()
        chooseService.frame = CGRect(x: 40, y: 100, width: UIScreen.main.bounds.width-80, height: 64)
        chooseService.textAlignment = .center
        chooseService.textColor = .black
        chooseService.fadeIn()
    }
    func hidePage2Elements() {
        emailField.fadeOut()
        passwordField.fadeOut()
        loginButton.fadeOut()
    }
    func hideLoginpage1Elements() {
        DispatchQueue.main.async {
            self.continueButton.fadeOut()
            self.chooseService.fadeOut()
                }
        if(transferringFrom == "itunes") {
            DispatchQueue.main.async {
                self.spotifyImage.fadeOut()
                self.iTunesButton.fadeOut()
                self.spotifyButton.fadeOut()
                
                //ALL ANIMATION STUFF TO MOVE ITUNES ICON AROUND
                self.backButton = self.createButton()
                self.backButton.alpha = 0
                self.backButton.setTitle("⇽ back", for: .normal)
                self.backButton.frame = CGRect(x: 0, y: 40, width: 100, height: 40)
                self.backButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 18)
                self.backButton.addTarget(self, action: #selector(self.backPressed(_:)), for: .touchUpInside)
                self.backButton.setTitleColor(self.hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.iTunesImage.frame = CGRect(x: UIScreen.main.bounds.width/2 - 32, y: self.iTunesImage.frame.minY, width: 64, height: 64)
                    self.iTunesImage.layer.borderWidth = 0
                }) { _ in
//                    viewToAnimate.removeFromSuperview()
                    UIView.animate(withDuration: 0.3) {
                        self.iTunesImage.frame = CGRect(x: UIScreen.main.bounds.width/2 - 32, y: self.iTunesImage.frame.minY - 120, width: 64, height: 64)
                        self.backButton.fadeIn()
                        self.addLoginpage2Elements()
                    }
                    
//                    self.emailField.fadeIn()
//                    self.passwordField.fadeIn()
                    
                }
                
            }
        } else {
            DispatchQueue.main.async {
                self.iTunesImage.fadeOut()
                self.spotifyImage.fadeOut()
                self.iTunesButton.fadeOut()
                self.spotifyButton.fadeOut()
                self.backButton = self.createButton()
                self.backButton.alpha = 0
                self.backButton.setTitle("⇽ back", for: .normal)
                self.backButton.frame = CGRect(x: 0, y: 40, width: 100, height: 40)
                self.backButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 18)
                self.backButton.addTarget(self, action: #selector(self.backPressed(_:)), for: .touchUpInside)
                self.backButton.setTitleColor(self.hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
                self.backButton.fadeIn()
//                self.backButton.setTitleColor(.black, for: .normal)
                self.loadSpotifyLogin()
            }
        }
        let seconds = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            DispatchQueue.main.async {
                self.playerLayer.player!.pause()
                self.playerLayer.removeFromSuperlayer()
            }
        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            DispatchQueue.main.async {
//                self.playerLayer.player?.currentItem?.removeObserver(self, forKeyPath: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, context: nil)
                self.playerLayer.player!.pause()
                self.playerLayer.removeFromSuperlayer()
            }
        }
    func addLoginpage2Elements() {
        
        
        emailField = createTextField()
        emailField.alpha = 0
        styleTextField(field: emailField)
        emailField.frame = CGRect(x: 50, y: 200, width: UIScreen.main.bounds.width - 100, height: 50)
        emailField.placeholder = "email"
        emailField.attributedPlaceholder = NSAttributedString(string: "email",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)])
        emailField.keyboardType = .emailAddress
        emailField.fadeIn()
        
        passwordField = createTextField()
        passwordField.alpha = 0
        styleTextField(field: passwordField)
        passwordField.frame = CGRect(x: 50, y: 280, width: UIScreen.main.bounds.width - 100, height: 50)
        passwordField.placeholder = "password"
        passwordField.attributedPlaceholder = NSAttributedString(string: "password",
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)])
        passwordField.isSecureTextEntry = true
        passwordField.fadeIn()
        
        loginButton = createButton()
        loginButton.alpha = 0
        loginButton.setTitle("login", for: .normal)
        loginButton.backgroundColor = hexStringToUIColor(hex: "#f0f3f4")
        loginButton.layer.borderColor = hexStringToUIColor(hex: "#c2c2c2").cgColor
        loginButton.layer.borderWidth = 1
//        continueButton.alpha = 1
        loginButton.layer.cornerRadius = 5
        loginButton.frame = CGRect(x: 50, y: UIScreen.main.bounds.height - 100, width: UIScreen.main.bounds.width - 100, height: 50)
        loginButton.fadeIn()
        loginButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 16)
        loginButton.addTarget(self, action: #selector(loginPressed(_:)), for: .touchUpInside)
        loginButton.setTitleColor(hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
        loginButton.dropShadow()
    }
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    func loopVideo(videoPlayer: AVPlayer) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            videoPlayer.seek(to: CMTime.zero)
            videoPlayer.play()
        }
    }
    func stopVideo() {
        playerLayer.player?.pause()
    }
    func loadSpotifyLogin() {
        print("* LOADING SPOTIFY LOGIN")
        DispatchQueue.main.async {
            //USE API TO GET AN AUTHORIZATION URL FOR US USING SCOPES
            let authorizationURL = self.spotify.authorizationManager.makeAuthorizationURL(
                redirectURI: URL(string: "https://www.google.com")!,
                showDialog: false,
                scopes: [
                    .playlistModifyPrivate,
                    .userModifyPlaybackState,
                    .playlistReadCollaborative,
                    .userReadPlaybackPosition,
                    .userFollowModify,
                    .playlistReadPrivate,
                    .playlistModifyPublic
                        
                ]
            )!
            print("* GOT AUTHORIZATION URL: \(authorizationURL)")
            //MAKE SURE AUTHENTICATION URL IS VALID
            if(authorizationURL.absoluteString.contains("spotify")) {
//                self.hideLoginpage1Elements()
                self.webView.load(URLRequest(url: authorizationURL))
            }
        }
        
    }
    func searchSpotify(query: String, type: IDCategory) {
        //INCLUDE ARTIST SO: GOOSEBUMPS TRAVIS SCOTT
        var returnVal: SpotifyWebAPI.Track!
        self.spotifySearchResults = []
        self.spotifySearchResults.removeAll()
        if(query != "") {
            self.spotify.search(query: query, categories: [type], limit: 14)
                .sink(
                    receiveCompletion: { completion in
    //                    return completion
                        print("completion result: \(completion)")
                        if case .failure(let error) = completion {
                                            print("COULD NOT SEARCH PROPERLY")
                                        }
                    },
                    receiveValue: { results in
    //                    print(results.tracks?.items[0])
                        //RETURN THE FIRST SEARCH RESULT WHICH IS PROBABLY THE CLOSEST
                        
                        if(type == .playlist) {
                            if(results.playlists!.items.isNotEmpty) {
                                let bestResult = results.playlists!.items[0]
                                let uri = bestResult.uri
                                print("******************************************************")
                                print("BEST SEARCH RESULT (PLAYLIST): \(bestResult.name) by \(bestResult.owner!.displayName ?? "")")
                                print("API ENDPOINT \(bestResult.items.href)")
                                if(bestResult.images.isEmpty) {
//                                    bestResult.images.append(SpotifyImage(height: 210, width: 221, url: URL(string: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")!))
                                } else {
                                    print("Cover photo: \(bestResult.images[0].url)")
                                }
                                
                                //prints out all elements in playlist
        //                       self.spotify.playlistItems(bestResult)
                                print("******************************************************")
        //                        print(bestResult)
        //                        spotify.playlistItems(uri as! SpotifyURIConvertible, limit: <#T##Int?#>, offset: <#T##Int?#>, market: <#T##String?#>)
        //                        self.getPlayListItemsFrom(uri: uri, offset: 0)
                                print("search length: \(results.playlists!.items.count)")
                                self.spotifySearchResults = []
                                self.spotifySearchResults.removeAll()
                                for result in results.playlists!.items {
                                    self.spotifySearchResults.append(result)
                                }
                                print("spotifysearchresults: \(self.spotifySearchResults.count)")
                                DispatchQueue.main.async {
                                    
                                    self.searchResultsViewController.reloadData()
                                }
                            }
                            
                        } else if (type == .track) {
                            let bestResult = results.tracks!.items[0]
                            print("******************************************************")
                            print("BEST SEARCH RESULT (TRACK): \(bestResult.name) by \(bestResult.artists![0].name)")
                            print("Cover photo: \(bestResult.album?.images![0].url.absoluteString as! String)")
                            print("song uri: \(bestResult.uri)")
                            print("******************************************************")
                        }
                        
                        
                        
                    }
                )
                .store(in: &self.cancellables)
        }
        
//        return returnVal
    }
    func addSongToQueue(query: String) {
        //For query do {Song name} SPACE {artist}
//        songQueue
        self.spotify.search(query: query, categories: [.track])
            .sink(
                receiveCompletion: { completion in
//                    return completion
                    print("completion result: \(completion)")
                    if case .failure(let error) = completion {
                                        print("COULD NOT SEARCH PROPERLY")
                                    }
                },
                receiveValue: { results in
//                    print(results.tracks?.items[0])
                    //RETURN THE FIRST SEARCH RESULT WHICH IS PROBABLY THE CLOSEST
                    let bestResult = results.tracks!.items[0]
                    //ADD SONG TO SONG QUEUE TO BE USED TO SAVE TO PLAYLIST
                    self.songQueue.append((bestResult.uri as! String) as! SpotifyURIConvertible)
                }
            ).store(in: &self.cancellables)
    }
    func getPlayListItemsFrom(uri: String, offset: Int?) {
        self.spotify.playlistItems(uri as! SpotifyURIConvertible, limit: 100, offset: offset ?? 0).sink(
            receiveCompletion: { completion in
//                    return completion
                print("completion result: \(completion)")
                if case .failure(let error) = completion {
                                    print("COULD NOT GET PLAYLIST INFO PROPERLY")
                                }
            },
            receiveValue: { results in
//                    print(results.tracks?.items[0])
                //RETURN THE FIRST SEARCH RESULT WHICH IS PROBABLY THE CLOSEST
                var songArr: [SpotifyURIConvertible] = []
//                print()
                for n in 0...results.items.count-1 {
                    //ADD EVERYSONG INTO AN ARRAY
                    songArr.append((results.items[n].item?.uri as! String) as! SpotifyURIConvertible)
                }
//                print(results)
//                results.items
                print("* total amount of songs loaded in playlist: \(songArr.count)")
//                self.addSongsToPlaylist(playlist: uri as! SpotifyURIConvertible, uris: songArr)
                if(results.next != nil) {
                    self.getPlayListItemsFrom(uri: uri, offset: (offset ?? 0)+100)
                }
//                print(songArr)
                //EXAMPLE TO ADD MULTIPLE SONGS TO PLAYLIST
//                self.addSongsToPlaylist(playlist: "spotify:playlist:78aV5gMM133PC1AOFhqe2v", uris: songArr)
            }
        )
        .store(in: &self.cancellables)
    }
    func createPlaylist(name: String, isPublic: Bool, isCollaborative: Bool, description: String) {
        self.spotify.currentUserProfile().sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                                    print("COULD NOT GET USER PROFILE PROPERLY")
                                }
            },
            receiveValue: { results in
                //use results.href to get API endpoint for this user
                print(results)
                let user = results.uri as! SpotifyURIConvertible
                print("current user profile url: \(user.uri)")
//                let uri: SpotifyURIConvertible
//                uri.uri = results.uri
                self.spotify.createPlaylist(for: user, PlaylistDetails(name: name, isPublic: isPublic, isCollaborative: isCollaborative, description: description)).sink(
                    receiveCompletion: { completion2 in
        //                    return completion
                        print("completion result: \(completion2)")
                        if case .failure(let error) = completion2 {
                                            print("COULD NOT CREATE NEW PLAYLIST")
                                        }
                    },
                    receiveValue: { results2 in
                        print("* successfully created playlist!")
                        let playlistURI = results2.uri as! SpotifyURIConvertible
                        print("* playlist internal url: \(playlistURI)")
                        //Here I add 90210 by travis scott to playlist as an example:
//                        self.addSongToPlaylist(playlistURI: playlistURI, songURI: "spotify:track:51EC3I1nQXpec4gDk0mQyP" as! SpotifyURIConvertible)
                        //here is an example of multiple at once (should add 90210, zeze, shoota, etc)
                        self.addSongsToPlaylist(playlist: playlistURI, uris: ["spotify:track:51EC3I1nQXpec4gDk0mQyP","spotify:track:0FZ4Dmg8jJJAPJnvBIzD9z", "spotify:track:2BJSMvOGABRxokHKB0OI8i"])
                    }
                )
                .store(in: &self.cancellables)
                
            }
        )
        .store(in: &self.cancellables)
    }
    func addSongToPlaylist(playlistURI: SpotifyURIConvertible, songURI: SpotifyURIConvertible) {
        self.spotify.addToPlaylist(playlistURI, uris: [songURI]).sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                                    print("COULD NOT ADD SONG TO PLAYLIST")
                                }
            },
            receiveValue: { results in
                print("* successfully added song to playlist!")
                
            }
        )
        .store(in: &self.cancellables)
    }
    func addSongsToPlaylist(playlist: SpotifyURIConvertible, uris: [SpotifyURIConvertible]) {
        self.spotify.addToPlaylist(playlist, uris: uris).sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                                    print("COULD NOT ADD SONGS TO PLAYLIST")
                                }
            },
            receiveValue: { results in
                print("* successfully added song to playlist!")
                
            }
        )
        .store(in: &self.cancellables)
    }
    func showSearchPart1() {
        //LOGAN HERE YOU CAN PUT YOUR UI
        currentStep = "search_1"
        searchBar = createTextField()
        searchBar.attributedPlaceholder = NSAttributedString(string: "Search or paste link for playlist",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray.withAlphaComponent(0.7)])
//        searchBar.placeHolderC
        let phoneWidth = UIScreen.main.bounds.width
        let phoneHeight = UIScreen.main.bounds.height
        let searchBarWidth = 300
        searchBar.font = UIFont(name: "HypermarketW00-Regular", size: 16)
        searchBar.backgroundColor = .white
        searchBar.textColor = hexStringToUIColor(hex: "#b8b8b8")
        searchBar.layer.cornerRadius = 5
        searchBar.frame = CGRect(x: (Int(phoneWidth)/2) - (searchBarWidth/2), y: 200, width: searchBarWidth, height: 45)
        searchBar.setLeftPaddingPoints(20)
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = hexStringToUIColor(hex: "#b8b8b8").withAlphaComponent(0.5).cgColor
        searchBar.addTarget(self, action: #selector(searchBarPressed(_:)), for: .touchDown)
        searchBar.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //WEBVIEW HAS STARTED LOADING GOOGLE.COM USE THIS TO GET AUTH CODE
        if ((webView.url?.absoluteString as! String).contains("google") && (webView.url?.absoluteString as! String).contains("accounts.spotify") == false) {
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
//                        now we want to show search bar and shit
                    //TESTING PLAYLIST CREATION
//                    self.createPlaylist(name: "test playlist", isPublic: true, isCollaborative: false, description: "test playlist -- ignore")
                    //EXAMPLE SEARCH FUNCTION
//                    self.searchForSong(query: "shoota playboi carti", type: .track)
//                    self.searchForSong(query: "bb shit", type: .playlist)
                    DispatchQueue.main.async {
                        self.showSearchPart1()
                    }
                    
                    case .failure(let error):
                        if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                            print("The user denied the authorization request")
                        }
                        else {
                            print("couldn't authorize application: \(error)")
                            
                            //CLEAR COOKIES AND SHOW LOGIN PAGE
                            let dataStore = WKWebsiteDataStore.default()
                            DispatchQueue.main.async {
                                dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
                                    for record in records {
                                        if record.displayName.contains("spotify") {
                                            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
    //                                            print("Deleted: " + record.displayName);
                                            })
                                        }
                                    }
                                    self.loadSpotifyLogin()
                                }
                            }
                            
                            
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
            webView.alpha = 1
            webView.isHidden = false
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
    @objc func searchBarPressed(_ sender: UITextField) {
        print("searchBarpressed pressed")
        searchResultsViewController.frame = CGRect(x: 5, y: 90+45, width: UIScreen.main.bounds.width - 10, height: UIScreen.main.bounds.height - 80 - 45)
        if(searchBar.frame.minY != 80) {
            UIView.animate(withDuration: 0.3, animations: {
                
                self.searchBar.frame = CGRect(x: 20, y: 80, width: UIScreen.main.bounds.width-40, height: 45)
            }) { _ in
                self.iTunesImage.removeFromSuperview()
//                self.addLoginPage1Elements()
//                self.playVideo(from: "Mobile_Web_BG.m4v")
            }
            
        }
        
    }
    @objc func continuePressed(_ sender: UIButton) {
        print("continue button pressed")
        if(transferringFrom != "") {
            hideLoginpage1Elements()
        } else {
            //USER NEEDS TO SELECT ITUNES OR SPOTIFY
            let alert = NewYorkAlertController(title: "Error", message: "please select which service you'd like to transfer a playlist to", style: .alert)
            
            let cancel = NewYorkButton(title: "ok", style: .cancel)
            
            alert.addButton(cancel)

            present(alert, animated: true)
        }
        
    }
    @objc func loginPressed(_ sender: UIButton) {
        print("login pressed")
    }
    @objc func backPressed(_ sender: UIButton) {
        print("back button pressed")
        if(currentStep == "spotify_login") {
            self.webView.fadeOut()
            backButton.fadeOut()
//            addLoginPage1Elements()
            playVideo(from: "Mobile_Web_BG.m4v")
        } else if (currentStep == "itunes_login") {
            backButton.fadeOut()
            hidePage2Elements()
            UIView.animate(withDuration: 0.5, animations: {
                
                self.iTunesImage.frame = CGRect(x: (UIScreen.main.bounds.width/2)-32 - 75,y: 200,width: 64, height: 64)
            }) { _ in
                self.iTunesImage.removeFromSuperview()
//                self.addLoginPage1Elements()
                self.playVideo(from: "Mobile_Web_BG.m4v")
            }
        } else if (currentStep == "search_1") {
            self.searchBar.fadeOut()
            UIView.animate(withDuration: 0.3, animations: {
//                self.searchBar.alpha = 0
                
                self.searchResultsViewController.alpha = 1
                self.spotifySearchResults.removeAll()
                self.searchResultsViewController.reloadData()
                self.backButton.fadeOut()
                self.searchBar.text = ""
            }) { _ in
                let searchBarWidth = 300
                self.searchBar.frame = CGRect(x: (Int(UIScreen.main.bounds.width)/2) - (searchBarWidth/2), y: 200, width: searchBarWidth, height: 45)
                
    //            addLoginPage1Elements()
                self.playVideo(from: "Mobile_Web_BG.m4v")
                self.searchBar.removeFromSuperview()
            }
            
        }
        
    }
    @objc func iTunesPressed(_ sender: UIButton) {
        print("iTunes button pressed")
        iTunesImage.layer.borderColor = hexStringToUIColor(hex: "#cccccc").cgColor
        iTunesImage.layer.cornerRadius = iTunesImage.frame.width / 2
        iTunesImage.layer.borderWidth = 5
        spotifyImage.layer.borderWidth = 0
        transferringFrom = "itunes"
        continueButton.backgroundColor = .white
        continueButton.setTitleColor(hexStringToUIColor(hex: "#b8b8b8"), for: .normal)
        currentStep = "itunes_login"
    }
    @objc func spotifyPressed(_ sender: UIButton) {
        print("spotify button pressed")
        currentStep = "spotify_login"
//        add a grey border around the selected button
        spotifyImage.layer.borderColor = hexStringToUIColor(hex: "#cccccc").cgColor
        //make it so that the border is circular and not a square
        spotifyImage.layer.cornerRadius = iTunesImage.frame.width / 2
        //make the border bigger (5px) make this number bigger to make the border bigger
        spotifyImage.layer.borderWidth = 5
        iTunesImage.layer.borderWidth = 0
        //for internal use: transferringFrom variable
        transferringFrom = "spotify"
        
        //make Continuebutton more "clickable"
        continueButton.backgroundColor = .white
        continueButton.setTitleColor(hexStringToUIColor(hex: "#b8b8b8"), for: .normal)
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

    func fadeIn(_ duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
    }, completion: completion)  }

    func fadeOut(_ duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
    }, completion: completion)
   }
}
extension UIApplication {
    static var clientId: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String
    }
    static var clientSecret: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CLIENT_SECRET") as? String
    }
}
extension UIView {
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
  // OUTPUT 1
  func dropShadow(scale: Bool = true) {
    layer.masksToBounds = false
    layer.shadowColor = hexStringToUIColor(hex: "#c2c2c2").cgColor
    layer.shadowOpacity = 0.4
      layer.cornerRadius = 5
//      layer.masksToBounds = true
      
    layer.shadowOffset = CGSize(width: 0, height: 4)
    layer.shadowRadius = 2

    layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    layer.shouldRasterize = true
      layer.rasterizationScale = scale ? UIScreen.main.scale : 1
  }

  // OUTPUT 2
  func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
    layer.masksToBounds = false
    layer.shadowColor = color.cgColor
    layer.shadowOpacity = opacity
    layer.shadowOffset = offSet
    layer.shadowRadius = radius

    layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    layer.shouldRasterize = true
    layer.rasterizationScale = scale ? UIScreen.main.scale : 1
  }
}
extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
