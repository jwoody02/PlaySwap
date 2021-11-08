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
import StoreKit

class searchTableViewCell: UITableViewCell {
    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var playlistCreaterLabel: UILabel!
    
    @IBOutlet weak var playlistCoverPhoto: UIImageView!
    @IBOutlet weak var selectButton: UIButton!
    var playlistItem: Playlist<PlaylistItemsReference>!
    var appleMusicPlaylistItem: [JSON]!
    var appleMusicPlaylistID: String!
}
class playlistTrackCell: UITableViewCell {
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackAuthorLabel: UILabel!
    @IBOutlet weak var trackLengthLabel: UILabel!
    @IBOutlet weak var trackImage: UIImageView!
    var trackItem: Track!
}
struct AppleMusicSong {
    var id: String
    var name: String
    var artistName: String
    var artworkURL: String
    var length: TimeInterval = 0
    init(id: String, name: String, artistName: String, artworkURL: String, length: TimeInterval) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
        self.artistName = artistName
        self.length = length
    }
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
    @IBOutlet weak var playlistContentsTableView: UITableView!
    //TRANSFER PAGE
    var playlistTitleLabel = UILabel()
    var playlistImage = UIImageView()
    var playlistDescription = UILabel()
    var playlistAuthor = UILabel()
    var playlistAuthorImage = UIImageView()
    var playlistTransferButton = UIButton()
    
    var backButton = UIButton()
    var spotifySearchResults : [Playlist<PlaylistItemsReference>] = []
    var appleMusicSearchResults : [AppleMusicSong] = []
    var transferButton = UIButton()
    
    var playlistTracks : [PlaylistItem] = []
    var appleMusicTracks : [AppleMusicSong] = []
    
    var appleMusicTransferPlaylist : [AppleMusicSong] = []
//    var appleMusic
    
    var spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowManager(
        clientId: "", clientSecret: ""
    ))
    
    //spotify_anonymous used when user is transferring to apple music
    var spotify_anonymous = SpotifyAPI(
                authorizationManager: ClientCredentialsFlowManager(
                    clientId: "", clientSecret: ""
                )
            )
        
    var playerLayer = AVPlayerLayer()
    
    var transferringFrom = ""
    
    var songQueue: [SpotifyURIConvertible] = []
    private var cancellables: Set<AnyCancellable> = []
    var transferType = "spotify" //spotify or itunes
    var currentStep = "choose_service"
    
//    ITUNES API KEY
    let developerToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiIsImtpZCI6IjU2NUNRMzg2NjUifQ.eyJpc3MiOiJaUkdVNTZGSDRMIiwiZXhwIjoxNjQ5ODQzODU5LCJpYXQiOjE2MzQwNzU4NTl9.Em7ap9NGQiLQp3cOU0kuccIPwDpXwQJAHzwkhPd7RPoFncnINUNCjnV6uxzVCS9MK0YOok3Rpa2ghVu7roFk7A"
    var appleMusicAuthToken = ""
    var appleMusicStoreFrontID = ""
    
    var playlistCoverPhoto = ""
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
        
        //FOR TESTING WHEN WE LOG INTO SPOTIFY & WANT TO TRANSFER TO SPOTIFY
        spotify = SpotifyAPI(
            authorizationManager: AuthorizationCodeFlowManager(
                clientId: UIApplication.clientId ?? "", clientSecret: UIApplication.clientSecret ?? ""
            )
        )
        searchResultsViewController.delegate = self
        searchResultsViewController.dataSource = self
        
        playlistContentsTableView.delegate = self
        playlistContentsTableView.dataSource = self
        playlistContentsTableView.backgroundColor = .clear
        
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
        searchResultsViewController.keyboardDismissMode = .onDrag
        
        playlistContentsTableView.rowHeight = 43
        playlistContentsTableView.keyboardDismissMode = .onDrag
        
//        playlistContentsTableView.separatorColor = hexStringToUIColor(hex: "#c2c2c2")
        playlistContentsTableView.separatorColor = .clear
        
    }
    func getUserToken(completion: @escaping(_ userToken: String) -> Void) -> Void {
        SKCloudServiceController().requestUserToken(forDeveloperToken: developerToken) { (userToken, error) in
            guard error == nil else {
                print("error: \(String(describing: error))")
                DispatchQueue.main.async {
                    let alert = NewYorkAlertController(title: "Error", message: "you do not have an active apple music subscription", style: .alert)
                    
                    let cancel = NewYorkButton(title: "ok", style: .cancel)
                    
                    alert.addButton(cancel)
                    self.iTunesImage.removeFromSuperview()
                    self.chooseService.removeFromSuperview()
                    self.spotifyImage.removeFromSuperview()
                    self.iTunesButton.removeFromSuperview()
                    self.spotifyButton.removeFromSuperview()
                    self.continueButton.removeFromSuperview()
                    self.backButton.fadeOut()
                    self.currentStep = "choose_service"
                    self.present(alert, animated: true)
//                    self.addLoginPage1Elements()
//                    self.playVideo(from: "Mobile_Web_BG.m4v")
                }
                
                           return
                      }
              
            print("got user token: \(String(describing: userToken))")
            self.appleMusicAuthToken = userToken ?? ""
            completion(userToken!)
        }
    }
    func getAppleMusicplaylistInfo(id: String, completion: @escaping([JSON]) -> Void) {
        //fix later
        let tmpStorefront = "us"
        let musicURL = URL(string: "https://api.music.apple.com/v1/catalog/\(tmpStorefront)/playlists/\(id)")!
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "GET"
        musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
//        musicRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
           
        URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
             guard error == nil else { return }
               
             if let json = try? JSON(data: data!) {
                 let result = (json["data"]).array!
                 print("got info on playlist")
//                 print(result)
                 completion(result)
             }
        }.resume()
    }
func fetchStorefrontID(userToken: String, completion: @escaping(String) -> Void){
     var storefrontID: String!
     let musicURL = URL(string: "https://api.music.apple.com/v1/me/storefront")!
     var musicRequest = URLRequest(url: musicURL)
     musicRequest.httpMethod = "GET"
     musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
     musicRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
     URLSession.shared.dataTask(with: musicRequest) { (data, response, error) in
          guard error == nil else { return }
            
          if let json = try? JSON(data: data!) {
              let result = (json["data"]).array!
              let id = (result[0].dictionaryValue)["id"]!
              storefrontID = id.stringValue
              print("got storefront id: \(String(describing: storefrontID))")
              completion(storefrontID)
          }
     }.resume()
}
    
    func hideSearchResults(){
            DispatchQueue.main.async {
                self.searchBar.fadeOut()
                self.searchResultsViewController.fadeOut()
            }
        }
    func showTransferPage() {
        currentStep = "transfer_page"
        dismissKeyboard()
        let tmp = 20
//        self.playlistImage.layer.cornerRadius = 13.0
//                    self.playlistImage.layer.shadowColor = UIColor.lightGray.cgColor
//                    self.playlistImage.layer.shadowOpacity = 0.5
//                    self.playlistImage.layer.shadowRadius = 10.0
//                    self.playlistImage.layer.shadowOffset = .zero
//                    self.playlistImage.layer.shadowPath = UIBezierPath(rect: self.playlistImage.bounds).cgPath
//                    self.playlistImage.layer.shouldRasterize = true
    //        DispatchQueue.main.async {
//        GENERAL PLAYLIST INFO
        self.playlistTitleLabel = self.createLabel()
        self.playlistTitleLabel.alpha = 0
        self.playlistTitleLabel.font = UIFont(name: "HypermarketW00-Regular", size: 18)
        self.playlistTitleLabel.text = ""
        self.playlistTitleLabel.frame = CGRect(x: 20+110+10, y: 75+tmp, width: Int(UIScreen.main.bounds.width)-110-10-10-10, height: 50)
        self.playlistTitleLabel.textAlignment = .left
        self.playlistTitleLabel.lineBreakMode = .byWordWrapping
        self.playlistTitleLabel.numberOfLines = 2
        self.playlistTitleLabel.textColor = .black
        self.playlistTitleLabel.fadeIn()
        
        
        self.playlistDescription = self.createLabel()
        self.playlistDescription.alpha = 0
        self.playlistDescription.font = UIFont(name: "HypermarketW00-Regular", size: 12)
        self.playlistDescription.text = "[no description]"
        self.playlistDescription.frame = CGRect(x: 20+110+10, y: 125+tmp, width: Int(UIScreen.main.bounds.width)-20-110-10-10, height: 30)
        playlistDescription.lineBreakMode = .byWordWrapping
        playlistDescription.numberOfLines = 2
        self.playlistDescription.textAlignment = .left
        self.playlistDescription.textColor = .lightGray
        self.playlistDescription.fadeIn()
        
        
        self.playlistAuthor = self.createLabel()
        self.playlistAuthor.alpha = 0
        self.playlistAuthor.font = UIFont(name: "HypermarketW00-Regular", size: 12)
        self.playlistAuthor.text = "[no author]"
        self.playlistAuthor.frame = CGRect(x: 20+110+10+30+5, y: CGFloat(Int(playlistDescription.frame.maxY)+10), width: UIScreen.main.bounds.width-40, height: 18)
        self.playlistAuthor.textAlignment = .left
        self.playlistAuthor.textColor = .black
        self.playlistAuthor.fadeIn()
        
        
        //IMAGES AND AUTHOR INFO
        self.playlistImage = self.createImage(named: "")
        self.playlistImage.dropShadow()
        self.playlistImage.layer.cornerRadius = 5
        self.playlistImage.fadeIn()
        self.playlistImage.frame = CGRect(x: 20,y: 80+tmp,width: 110, height: 110)
        self.playlistImage.contentMode = .scaleAspectFill
        //AUTTHOR IMAGE
        self.playlistAuthorImage = self.createImage(named: "")
        self.playlistAuthorImage.dropShadow()
//        self.playlistAuthorImage.layer.cornerRadius = 5
        self.playlistAuthorImage.fadeIn()
        self.playlistAuthorImage.frame = CGRect(x: 20+110+10,y: Int(playlistDescription.frame.maxY)+5,width: 30, height: 30)
        self.playlistAuthorImage.layer.cornerRadius = playlistAuthorImage.frame.width / 2 //creates a circular image
    //        }
        
//        self.view.addSubview(playlistContentsTableView)
        playlistContentsTableView.alpha = 0
        let y = 80+110+20+10+tmp+50
        playlistContentsTableView.frame = CGRect(x: 0, y: CGFloat(y), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - CGFloat((y)))
    }
    func backupshowTransferPage(){
        currentStep = "transfer_page"
        dismissKeyboard()
//        self.playlistImage.layer.cornerRadius = 13.0
//                    self.playlistImage.layer.shadowColor = UIColor.lightGray.cgColor
//                    self.playlistImage.layer.shadowOpacity = 0.5
//                    self.playlistImage.layer.shadowRadius = 10.0
//                    self.playlistImage.layer.shadowOffset = .zero
//                    self.playlistImage.layer.shadowPath = UIBezierPath(rect: self.playlistImage.bounds).cgPath
//                    self.playlistImage.layer.shouldRasterize = true
    //        DispatchQueue.main.async {
//        GENERAL PLAYLIST INFO
        self.playlistTitleLabel = self.createLabel()
        self.playlistTitleLabel.alpha = 0
        self.playlistTitleLabel.font = UIFont(name: "HypermarketW00-Regular", size: 20)
        self.playlistTitleLabel.text = ""
        self.playlistTitleLabel.frame = CGRect(x: 20, y: 310, width: UIScreen.main.bounds.width-40, height: 18)
        self.playlistTitleLabel.textAlignment = .left
        self.playlistTitleLabel.textColor = .black
        self.playlistTitleLabel.fadeIn()

        
        self.playlistDescription = self.createLabel()
        self.playlistDescription.alpha = 0
        self.playlistDescription.font = UIFont(name: "HypermarketW00-Regular", size: 12)
        self.playlistDescription.text = "[no description]"
        self.playlistDescription.frame = CGRect(x: 20, y: 310+28, width: UIScreen.main.bounds.width-40, height: 18)
        self.playlistDescription.textAlignment = .left
        self.playlistDescription.textColor = .lightGray
        self.playlistDescription.fadeIn()
        
        
        self.playlistAuthor = self.createLabel()
        self.playlistAuthor.alpha = 0
        self.playlistAuthor.font = UIFont(name: "HypermarketW00-Regular", size: 12)
        self.playlistAuthor.text = "[no author]"
        self.playlistAuthor.frame = CGRect(x: 18+42, y: 310+28+30, width: UIScreen.main.bounds.width-40, height: 18)
        self.playlistAuthor.textAlignment = .left
        self.playlistAuthor.textColor = .black
        self.playlistAuthor.fadeIn()
        
        
        //IMAGES AND AUTHOR INFO
        self.playlistImage = self.createImage(named: "")
        self.playlistImage.dropShadow()
        self.playlistImage.layer.cornerRadius = 5
        self.playlistImage.fadeIn()
        self.playlistImage.frame = CGRect(x: (UIScreen.main.bounds.width/2)-100,y: 80,width: 200, height: 200)
        //AUTTHOR IMAGE
        self.playlistAuthorImage = self.createImage(named: "")
        self.playlistAuthorImage.dropShadow()
//        self.playlistAuthorImage.layer.cornerRadius = 5
        self.playlistAuthorImage.fadeIn()
        self.playlistAuthorImage.frame = CGRect(x: 20,y: 310+28+25,width: 30, height: 30)
        self.playlistAuthorImage.layer.cornerRadius = playlistAuthorImage.frame.width / 2 //creates a circular image
    //        }
        
//        self.view.addSubview(playlistContentsTableView)
        playlistContentsTableView.alpha = 0
        playlistContentsTableView.frame = CGRect(x: 0, y: 310+28+25+45, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - (310+28+25+35))
        
        
    }
    func selectRow(tableView: UITableView, position: Int) {
        let sizeTable = tableView.numberOfRows(inSection: 0)
        guard position >= 0 && position < sizeTable else { return }
        let indexPath = IndexPath(row: position, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
    }
    @IBAction func cellPressed(_ sender: UIButton) {
        print("selecting row \(sender.tag)")
        selectRow(tableView: searchResultsViewController,position: sender.tag)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        print("detected change in text field -- searching")
        if(textField.text != "") {
            if(transferringFrom == "spotify") {
                searchSpotify(query: textField.text ?? "", type: .playlist)
                let str = textField.text ?? ""
                if(str.contains("open.spotify") && str.contains("playlist")){
//        https://open.spotify.com/playlist/2Q92TIbw4mPpumNFnF8cCE?si=9Z3ao0hdRBir_08C3wOUbw
                    let componentspenis = str.components(separatedBy: "/")
                    let question = (componentspenis.last ?? "").components(separatedBy: "?")
                    let SpotifyURI = "spotify:playlist:" + (question.first ?? "")
                    
                    getPlayListItemsFrom(uri: SpotifyURI, offset: 0)
                    print("white girls")
                DispatchQueue.main.async{
                    self.transferButton = self.createButton()
                    
                    self.transferButton.alpha = 0
                    self.transferButton.addTarget(self, action: #selector(self.transferPressed(_:)), for: .touchUpInside)
                    
                    self.transferButton.isUserInteractionEnabled = true
                    self.transferButton.fadeIn()
        //            self.transferButton.isUserInteractionEnabled = false
                    if(self.transferringFrom == "spotify") {
                        self.transferButton.setTitle("transfer to apple music", for: .normal)
                    }
                    else {
                        self.transferButton.setTitle("transfer to spotify", for: .normal)
                    }
                    self.transferButton.backgroundColor = .white
                    self.transferButton.layer.borderColor = self.hexStringToUIColor(hex: "#c2c2c2").cgColor
                    self.transferButton.layer.borderWidth = 1
            //        continueButton.alpha = 1
                    self.transferButton.layer.cornerRadius = 5
                    self.transferButton.frame = CGRect(x: 20, y: 220, width: UIScreen.main.bounds.width - 40, height: 50)
                    
                    self.transferButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 16)
                    self.transferButton.setTitleColor(self.hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
                    self.transferButton.dropShadow()
                }
                    spotify_anonymous.playlist(SpotifyURI, market: "us").sink(
                        receiveCompletion: { completion in
                            
                        },
                        receiveValue: { results in
                            DispatchQueue.main.async {
                                self.playlistTracks.removeAll()
                                self.hideSearchResults()
                                self.showTransferPage()
                                self.playlistTitleLabel.text = results.name
                                    if(results.description != "") {
                                        self.playlistDescription.text = results.description
                                    }
                                    
                                self.playlistAuthor.text = results.owner?.displayName
                                    //ALL THIS IS TO PUT OWNER'S PROFILE PICTURE IN
                                self.spotify_anonymous.userProfile(results.owner?.uri as! SpotifyURIConvertible).sink(
                                        receiveCompletion: { completion in
                                            
                                        },
                                        receiveValue: { results in
                                            print(results)
                                            DispatchQueue.main.async {
                                                
                                                if((results.images!.isNotEmpty)) {
                                                    print("* USERS PROFILE PICS: \(String(describing: results.images))")
                                                    self.playlistAuthorImage.downloaded(from: (results.images?.last?.url)!)
                                                    self.playlistAuthorImage.fadeIn()
                                                    self.playlistAuthorImage.clipsToBounds = true
                                                    self.playlistImage.clipsToBounds = true
                                                    self.playlistImage.contentMode = .scaleAspectFill
                                                } else {
                                                    //playlist doesnt have image -- show placeholder
                                                    self.playlistAuthorImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                                                    self.playlistAuthorImage.fadeIn()
                                                    self.playlistAuthorImage.clipsToBounds = true
                                                    self.playlistImage.clipsToBounds = true
                                                }
                                            }
                                            
                                        }
                                    )
                                    .store(in: &self.cancellables)
                                    
    //                                print("*playlist description: \(spotifySearchResults[1].description)")
                                
                                
                                self.playlistImage.alpha = 0
    //                            if(spotifySearchResults.count-1 >= 0) {
                                    if(results.images.isNotEmpty) {
                                        self.playlistImage.downloaded(from: results.images[0].url)
                                        self.playlistCoverPhoto = results.images[0].url.absoluteString
                                        self.playlistImage.fadeIn()
                                    } else {
                                        //playlist doesnt have image -- show placeholder
                                        self.playlistImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                                        self.playlistImage.fadeIn()
                                    }
                            }
                            
//                            }
                            
                        }
                    )
                    .store(in: &self.cancellables)
                    
                }
            } else {
                let str = textField.text ?? ""
                if(str.contains("music.apple") && str.contains("playlist")){
                    let components = str.components(separatedBy: "/")
                    let AppleURI = components.last
                    getAppleMusicplaylistInfo(id: AppleURI ?? "") { playlist in
                        DispatchQueue.main.async{
                            self.hideSearchResults()
                            self.showTransferPage()
                            self.playlistTitleLabel.text = playlist[0]["attributes"]["name"].string
                            self.playlistAuthor.text = playlist[0]["attributes"]["curatorName"].string
                            self.playlistImage.downloaded(from: String((playlist[0]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "400x400")))
                            self.playlistTitleLabel.fadeIn()
                            print(playlist[0]["attributes"]["artwork"]["url"])
                            self.playlistDescription.text = playlist[0]["attributes"]["description"]["short"].string
                            self.playlistAuthorImage.clipsToBounds = true
                            self.playlistCoverPhoto = String((playlist[0]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "400x400"))
                            self.playlistImage.clipsToBounds = true
                            self.playlistImage.layer.cornerRadius = 5
                            
                            self.playlistAuthorImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                            self.playlistAuthorImage.fadeIn()
                            self.appleMusicTracks.removeAll()
                            let tracks = JSON(playlist[0]["relationships"]["tracks"]["data"])
                            var i = 0
                            for track in tracks {
                                //artistName or composerName
                                self.appleMusicTracks.append(AppleMusicSong(id: tracks[i]["id"].string ?? "", name: tracks[i]["attributes"]["name"].string ?? "", artistName: tracks[i]["attributes"]["artistName"].string ?? "", artworkURL: (tracks[i]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "128x128"), length: TimeInterval(Double(tracks[i]["attributes"]["durationInMillis"].int ?? 0))))
                                i=i+1
                            }
                            print("found all tracks showing table")
                            self.playlistContentsTableView.reloadData()
                            self.playlistContentsTableView.fadeIn()
                            self.transferButton = self.createButton()
                            
                            self.transferButton.alpha = 0
                            self.transferButton.addTarget(self, action: #selector(self.transferPressed(_:)), for: .touchUpInside)
                            
                            self.transferButton.isUserInteractionEnabled = true
                            self.transferButton.fadeIn()
                //            self.transferButton.isUserInteractionEnabled = false
                            if(self.transferringFrom == "spotify") {
                                self.transferButton.setTitle("transfer to apple music", for: .normal)
                            }
                            else {
                                self.transferButton.setTitle("transfer to spotify", for: .normal)
                            }
                            self.transferButton.backgroundColor = .white
                            self.transferButton.layer.borderColor = self.hexStringToUIColor(hex: "#c2c2c2").cgColor
                            self.transferButton.layer.borderWidth = 1
                    //        continueButton.alpha = 1
                            self.transferButton.layer.cornerRadius = 5
                            self.transferButton.frame = CGRect(x: 20, y: 220, width: UIScreen.main.bounds.width - 40, height: 50)
                            
                            self.transferButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 16)
                            self.transferButton.setTitleColor(self.hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
                            self.transferButton.dropShadow()
                        }
                    }
                }
                else{
                    searchAppleMusic(searchTerm: str)
                }
                
                //ADDING URI to APPLE MUSIC SEARCH
                 
                 
                 
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == searchResultsViewController) {
            if(transferringFrom == "spotify") {
                return spotifySearchResults.count
            } else {
                return appleMusicSearchResults.count
            }
            
        } else {
            if(transferringFrom == "spotify") {
                return playlistTracks.count
            } else {
                return appleMusicTracks.count
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView != playlistContentsTableView) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! searchTableViewCell
            transferButton = createButton()
            
            transferButton.alpha = 0
            transferButton.addTarget(self, action: #selector(transferPressed(_:)), for: .touchUpInside)
            
            self.transferButton.isUserInteractionEnabled = true
            self.transferButton.fadeIn()
//            self.transferButton.isUserInteractionEnabled = false
            if(transferringFrom == "spotify") {
                transferButton.setTitle("transfer to apple music", for: .normal)
            }
            else {
                transferButton.setTitle("transfer to spotify", for: .normal)
            }
            transferButton.backgroundColor = .white
            transferButton.layer.borderColor = hexStringToUIColor(hex: "#c2c2c2").cgColor
            transferButton.layer.borderWidth = 1
    //        continueButton.alpha = 1
            transferButton.layer.cornerRadius = 5
            transferButton.frame = CGRect(x: 20, y: 220, width: UIScreen.main.bounds.width - 40, height: 50)
            
            transferButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 16)
            transferButton.setTitleColor(hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
            transferButton.dropShadow()
    //        tableView.deselectRow(at: indexPath, animated: true)
            if(transferringFrom == "spotify") {
                print(spotifySearchResults[indexPath.row])
                print("internal uri: \(spotifySearchResults[indexPath.row].uri)")
                getPlayListItemsFrom(uri: spotifySearchResults[indexPath.row].uri, offset: 0)
                playlistTracks.removeAll()
                hideSearchResults()
                showTransferPage()
                if(spotifySearchResults.count-1 >= indexPath.row) {
                    playlistTitleLabel.text = spotifySearchResults[indexPath.row].name
                    if(spotifySearchResults[indexPath.row].description != "") {
                        playlistDescription.text = spotifySearchResults[indexPath.row].description
                    }
                    
                    playlistAuthor.text = spotifySearchResults[indexPath.row].owner?.displayName
                    //ALL THIS IS TO PUT OWNER'S PROFILE PICTURE IN
                    spotify_anonymous.userProfile(spotifySearchResults[indexPath.row].owner?.uri as! SpotifyURIConvertible).sink(
                        receiveCompletion: { completion in
                            
                        },
                        receiveValue: { results in
                            print(results)
                            DispatchQueue.main.async {
                                
                                if((results.images!.isNotEmpty)) {
                                    print("* USERS PROFILE PICS: \(String(describing: results.images))")
                                    self.playlistAuthorImage.downloaded(from: (results.images?.last?.url)!)
                                    self.playlistAuthorImage.fadeIn()
                                    self.playlistAuthorImage.clipsToBounds = true
                                    self.playlistImage.clipsToBounds = true
                                    self.playlistImage.contentMode = .scaleAspectFill
                                } else {
                                    //playlist doesnt have image -- show placeholder
                                    self.playlistAuthorImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                                    self.playlistAuthorImage.fadeIn()
                                    self.playlistAuthorImage.clipsToBounds = true
                                    self.playlistImage.clipsToBounds = true
                                }
                            }
                            
                        }
                    )
                    .store(in: &self.cancellables)
                    
                    print("*playlist description: \(String(describing: spotifySearchResults[indexPath.row].description))")
                }
                
                playlistImage.alpha = 0
                if(spotifySearchResults.count-1 >= indexPath.row) {
                    if(spotifySearchResults[indexPath.row].images.isNotEmpty) {
                        playlistImage.downloaded(from: spotifySearchResults[indexPath.row].images[0].url)
                        playlistCoverPhoto = spotifySearchResults[indexPath.row].images[0].url.absoluteString
                        playlistImage.fadeIn()
                    } else {
                        //playlist doesnt have image -- show placeholder
                        playlistImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                        playlistImage.fadeIn()
                    }
                }
                
            } else {
//                appleMusicSearchResults
                print("getting more info on playlist: \(appleMusicSearchResults[indexPath.row].id)")
                hideSearchResults()
//                searchResultsViewController.fadeOut()
                showTransferPage()
                getAppleMusicplaylistInfo(id: appleMusicSearchResults[indexPath.row].id) { playlist in
                    //completion
                    print("populating playlist info")
                    if(self.appleMusicSearchResults.count-1 >= indexPath.row) {
                        DispatchQueue.main.async {
                            self.playlistTitleLabel.text = self.appleMusicSearchResults[indexPath.row].name
                            self.playlistAuthor.text = self.appleMusicSearchResults[indexPath.row].artistName
                            self.playlistDescription.text = playlist[0]["attributes"]["description"]["short"].string
                            self.playlistAuthorImage.clipsToBounds = true
                            
                            self.playlistImage.downloaded(from: String((playlist[0]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "400x400")))
                            self.playlistCoverPhoto = String((playlist[0]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "400x400"))
                            self.playlistImage.clipsToBounds = true
                            self.playlistImage.layer.cornerRadius = 5
                            
                            self.playlistAuthorImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                            self.playlistAuthorImage.fadeIn()
                            self.appleMusicTracks.removeAll()
                            let tracks = JSON(playlist[0]["relationships"]["tracks"]["data"])
                            var i = 0
                            for track in tracks {
                                //artistName or composerName
                                self.appleMusicTracks.append(AppleMusicSong(id: tracks[i]["id"].string ?? "", name: tracks[i]["attributes"]["name"].string ?? "", artistName: tracks[i]["attributes"]["artistName"].string ?? "", artworkURL: (tracks[i]["attributes"]["artwork"]["url"].string ?? "").replacingOccurrences(of: "{w}x{h}", with: "128x128"), length: TimeInterval(Double(tracks[i]["attributes"]["durationInMillis"].int ?? 0))))
                                i=i+1
                            }
                            print("found all tracks showing table")
                            self.playlistContentsTableView.reloadData()
                            self.playlistContentsTableView.fadeIn()
//                            self.playlistImage.downloaded(from: playlist[0]["artwork"]["url"].string!)
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == searchResultsViewController) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! searchTableViewCell
            
            cell.playlistCoverPhoto.image = nil
            if(transferringFrom == "spotify") {
                //SET LABELS AND SUCH
                if(spotifySearchResults.count > indexPath.row) {
                    cell.playlistNameLabel.text = (spotifySearchResults[indexPath.row].name )
                    cell.playlistCreaterLabel.text = (spotifySearchResults[indexPath.row].owner?.displayName ?? "")
                    if(spotifySearchResults.count-1 <= indexPath.row) {
                        if(spotifySearchResults[indexPath.row].images.isNotEmpty && spotifySearchResults[indexPath.row] != nil) {
                            print("playlist images: \(spotifySearchResults[indexPath.row].images)")
                            cell.playlistCoverPhoto.downloaded(from: spotifySearchResults[indexPath.row].images.last!.url)
                            cell.playlistCoverPhoto.contentMode = .scaleAspectFill
                        } else {
                            //playlist doesnt have image -- show placeholder
                            cell.playlistCoverPhoto.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                            cell.playlistCoverPhoto.contentMode = .scaleAspectFill
                        }
                    }
                    
                }
            } else {
//                print("apple music row!")
                if(appleMusicSearchResults.count > indexPath.row) {
                    cell.playlistNameLabel.text = appleMusicSearchResults[indexPath.row].name
                    //fix this shit later
                    cell.playlistCreaterLabel.text = (appleMusicSearchResults[indexPath.row].artistName )
                    cell.appleMusicPlaylistID = appleMusicSearchResults[indexPath.row].id
                    print("apple music playlistid: \(appleMusicSearchResults[indexPath.row].id)")
                    if(appleMusicSearchResults[indexPath.row].artworkURL != "") {
                        print("playlist images: \(appleMusicSearchResults[indexPath.row].artworkURL)")
                        cell.playlistCoverPhoto.downloaded(from: appleMusicSearchResults[indexPath.row].artworkURL.replacingOccurrences(of: "{w}x{h}", with: "128x128"))
                        cell.playlistCoverPhoto.contentMode = .scaleAspectFill
                    } else {
                        //playlist doesƒnt have image -- show placeholder
                        cell.playlistCoverPhoto.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                        cell.playlistCoverPhoto.contentMode = .scaleAspectFill
                    }
                }
            }
            
            cell.selectButton.tag = indexPath.row
    //        cell.playlistItem = spotifySearchResults[indexPath.row]
            cell.selectionStyle = .none
            
            return cell
        } else {
            if(transferringFrom == "spotify") {
                let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath) as! playlistTrackCell
                cell.trackAuthorLabel.font = UIFont(name: "HypermarketW00-Regular", size: 12)
                cell.trackNameLabel.frame = CGRect(x: 20+40, y: 3, width: UIScreen.main.bounds.width-100, height: 18)
                cell.trackAuthorLabel.frame = CGRect(x: 20+40, y: 21, width: UIScreen.main.bounds.width-100, height: 18)
                cell.trackLengthLabel.frame = CGRect(x: UIScreen.main.bounds.width-100-15, y: (43/2)-9, width: 90, height: 18)
                cell.trackNameLabel.font = UIFont(name: "HypermarketW00-Regular", size: 14)
                cell.trackNameLabel.text = playlistTracks[indexPath.row].name
                let msInterval : TimeInterval = Double(playlistTracks[indexPath.row].durationMS!/1000)
                cell.trackLengthLabel.text = msInterval.minuteSecondMS
                cell.trackImage.clipsToBounds = true
                cell.trackImage.layer.cornerRadius = 5
                cell.trackImage.frame = CGRect(x: 20, y: 6.5, width: 32, height: 32)
                cell.trackLengthLabel.textAlignment = .right
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                cell.trackLengthLabel.font = UIFont(name: "HypermarketW00-Regular", size: 14)
                spotify_anonymous.track(playlistTracks[indexPath.row].uri!, market: "us").sink(
                    receiveCompletion: { completion in
                        
                    },
                    receiveValue: { results in
    //                    print(results)
                        DispatchQueue.main.async {
                            var txt = ""
                            cell.trackItem = results
                            if(results.album != nil) {
                                print("playlist images: \(String(describing: results.album?.images))")
                                cell.trackImage.downloaded(from: (results.album?.images?[0].url)!)
                                cell.trackImage.contentMode = .scaleAspectFill
                            } else {
                                //playlist doesnt have image -- show placeholder
                                cell.trackImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                                cell.trackImage.contentMode = .scaleAspectFill
                            }
                            for i in results.artists! {
                                if(i != results.artists?.last) {
                                    if(txt == "") {
                                        txt = "\(i.name),"
                                    } else {
                                        txt = "\(txt) \(i.name),"
                                    }
                                    
                                } else {
                                    if(txt == "") {
                                        txt = i.name
                                    } else {
                                        txt = "\(txt) \(i.name)"
                                    }
                                    
                                }
                                
                            }
                            cell.trackAuthorLabel.text = txt
                        }
                        
                    }
                )
                .store(in: &self.cancellables)
    //            cell.trackItem = playlistTracks[indexPath.row]
                cell.selectionStyle = .none
                return cell
            } else {
//                print("apple music cell")
                let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath) as! playlistTrackCell
                cell.trackAuthorLabel.font = UIFont(name: "HypermarketW00-Regular", size: 12)
                cell.trackNameLabel.frame = CGRect(x: 20+40, y: 3, width: UIScreen.main.bounds.width-100, height: 18)
                cell.trackAuthorLabel.frame = CGRect(x: 20+40, y: 21, width: UIScreen.main.bounds.width-100, height: 18)
                cell.trackLengthLabel.frame = CGRect(x: UIScreen.main.bounds.width-100-15, y: (43/2)-9, width: 90, height: 18)
                cell.trackNameLabel.font = UIFont(name: "HypermarketW00-Regular", size: 14)
                
                let msInterval : TimeInterval = Double(appleMusicTracks[indexPath.row].length/1000)
                
                cell.trackImage.clipsToBounds = true
                cell.trackImage.layer.cornerRadius = 5
                cell.trackImage.frame = CGRect(x: 20, y: 6.5, width: 32, height: 32)
                cell.trackLengthLabel.textAlignment = .right
                cell.backgroundColor = .clear
                
                cell.trackLengthLabel.font = UIFont(name: "HypermarketW00-Regular", size: 14)
//                print("*track name: \(appleMusicTracks)")
                cell.trackLengthLabel.text = msInterval.minuteSecondMS
                cell.trackNameLabel.text = appleMusicTracks[indexPath.row].name
                cell.trackAuthorLabel.text = appleMusicTracks[indexPath.row].artistName
                if(appleMusicTracks[indexPath.row].artworkURL != nil) {
                    print("playlist images: \(appleMusicTracks[indexPath.row].artworkURL)")
                    cell.trackImage.downloaded(from: (appleMusicTracks[indexPath.row].artworkURL))
                    cell.trackImage.contentMode = .scaleAspectFill
                } else {
                    //playlist doesnt have image -- show placeholder
                    cell.trackImage.downloaded(from: "https://user-images.githubusercontent.com/24848110/33519396-7e56363c-d79d-11e7-969b-09782f5ccbab.png")
                    cell.trackImage.contentMode = .scaleAspectFill
                }
                cell.selectionStyle = .none
                return cell
            }
        }
        
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
        if(transferringFrom == "spotify") {
            DispatchQueue.main.async {
                self.spotifyImage.fadeOut()
                self.iTunesButton.fadeOut()
                self.spotifyButton.fadeOut()
                self.iTunesImage.fadeOut()
                //ALL ANIMATION STUFF TO MOVE ITUNES ICON AROUND
                self.backButton = self.createButton()
                self.backButton.alpha = 0
                self.backButton.setTitle("⇽ back", for: .normal)
                self.backButton.frame = CGRect(x: 0, y: 40, width: 100, height: 40)
                self.backButton.titleLabel?.font = UIFont(name: "HypermarketW00-Regular", size: 18)
                self.backButton.addTarget(self, action: #selector(self.backPressed(_:)), for: .touchUpInside)
                self.backButton.setTitleColor(self.hexStringToUIColor(hex: "#c2c2c2"), for: .normal)
                self.backButton.fadeIn()
                print("attempting to get user to sign in")
                SKCloudServiceController.requestAuthorization { [self] (status) in
                        if status == .authorized {
                            //LOG INTO APPLE MUSIC
                            print("we're authorized?")
                            getUserToken{ userToken in
                                fetchStorefrontID(userToken: userToken){ storefrontID in
                                    print(storefrontID)
                                    appleMusicStoreFrontID = storefrontID
                                    //looks like we're logged in
//                                    ANONYMOUS SPOTIFY LOGIN
                                    DispatchQueue.main.async {
                                        spotify_anonymous = SpotifyAPI(
                                            authorizationManager: ClientCredentialsFlowManager(
                                                clientId: UIApplication.clientId ?? "", clientSecret: UIApplication.clientSecret ?? ""
                                            )
                                        )
                                        spotify_anonymous.authorizationManager.authorize()
                                            .sink(receiveCompletion: { completion in
                                                switch completion {
                                                    case .finished:
                                                        print("successfully authorized application")
                                                    case .failure(let error):
                                                        print("could not authorize application: \(error)")
                                                }
                                            })
                                            .store(in: &cancellables)
                                        showSearchPart1()
                                    }
                                    
                                }
                            }
                            
                        } else {
                            print("looks like we arent authorized: \(status)")
                        }
                    }
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.iTunesImage.frame = CGRect(x: UIScreen.main.bounds.width/2 - 32, y: self.iTunesImage.frame.minY, width: 64, height: 64)
//                    self.iTunesImage.layer.borderWidth = 0
//                }) { _ in
////                    viewToAnimate.removeFromSuperview()
//                    UIView.animate(withDuration: 0.3) {
//                        self.iTunesImage.frame = CGRect(x: UIScreen.main.bounds.width/2 - 32, y: self.iTunesImage.frame.minY - 120, width: 64, height: 64)
//                        self.backButton.fadeIn()
//                        self.addLoginpage2Elements()
//                    }
//
////                    self.emailField.fadeIn()
////                    self.passwordField.fadeIn()
//
//                }
                
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
                    .playlistModifyPublic,
                    .ugcImageUpload
                        
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
    func searchAppleMusicForSong(searchTerm: String, trackNum: Int, totalTracks: Int) {
        //you can change this to different countries
        let tmpStoreFront = "us"
        let musicURL = URL(string: "https://api.music.apple.com/v1/catalog/\(tmpStoreFront)/search?term=\((searchTerm.replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "") )&types=songs&limit=1")!
        //        print("requesting url: \(musicURL)")
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "GET"
        musicRequest.addValue("Bearer \(self.developerToken)", forHTTPHeaderField: "Authorization")
        //            musicRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: musicRequest) { [self] (data, response, error) in
            guard error == nil else { return }
            if let json = try? JSON(data: data!) {
                //                            print(json)
                
//                if((json["results"]["playlists"]["data"]).array != nil) {
//                    self.appleMusicSearchResults.removeAll()
//                    let result = (json["results"]["playlists"]["data"]).array!
//                    for song in result {
//                        let attributes = song["attributes"]
//                        let currentSong = AppleMusicSong(id: attributes["playParams"]["id"].string ?? "", name: attributes["name"].string ?? "", artistName: attributes["curatorName"].string ?? "", artworkURL: attributes["artwork"]["url"].string ?? "", length:  TimeInterval(Double(0)))
//                        //                            songs.append(currentSong)
//                        self.appleMusicSearchResults.append(currentSong)
//                    }
//                    DispatchQueue.main.async {
//                        self.searchResultsViewController.reloadData()
//                        //                                    self.searchResultsViewController.fadeIn()
//                    }
//                }
                if(json["results"]["songs"]["data"].array != nil) {
                    let song = json["results"]["songs"]["data"][0]
                    if(song["attributes"]["name"].stringValue != "") {
                        let temp = AppleMusicSong(id: song["id"].stringValue, name: song["attributes"]["name"].stringValue, artistName: song["attributes"]["artistName"].stringValue, artworkURL: song["attributes"]["artwork"]["url"].stringValue, length: song["attributes"]["durationInMillis"].doubleValue)
                        appleMusicTransferPlaylist.append(temp)
                        print("found song: \(json["results"]["songs"]["data"][0]["attributes"]["name"].stringValue)")
                    }
                    
                    
                }
                DispatchQueue.main.async {
                    if let buttonTitle = self.transferButton.title(for: .normal) {
                        if(buttonTitle.contains("finish")) {
                            
                        } else {
                            self.transferButton.setTitle("transferring from \(self.transferringFrom) (\(trackNum)/\(totalTracks))", for: .normal)
                        }
                      }
                    
                }
//                print("JSON RESULT")
                
//                print(json)
                if trackNum == totalTracks-1 {
                    DispatchQueue.main.async {
                        createAppleMusicPlaylistWith(name: playlistTitleLabel.text ?? "", description: playlistDescription.text ?? "", tracks: appleMusicTransferPlaylist)
                    }
                    
                }
            } else {
                //                        lock.signal()
            }
        }.resume()
    }
    func createAppleMusicPlaylistWith(name: String, description: String, tracks: [AppleMusicSong]) {
        appleMusicTransferPlaylist.removeAll()
        print("creating apple music playlist")
        let musicURL = URL(string: "https://api.music.apple.com/v1/me/library/playlists")!
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "POST"
        var dataArray: [[String: Any]] = []
        var i = 0
        for son in appleMusicTransferPlaylist {
            let temp: [String: Any] = [
                "data" : [
                    "id": son.id,
                    "type": "songs"
                ]
            ]
            dataArray.append(temp)
            i=i+1
        }
        let createPlaylistBody: [String: Any] = [
            "attributes":[
                "name": name,
                "description":description
            ]
        ]
        musicRequest.httpBody = createPlaylistBody.percentEncoded()
        musicRequest.addValue("Bearer \(self.developerToken)", forHTTPHeaderField: "Authorization")
        SKCloudServiceController().requestUserToken(forDeveloperToken: developerToken) { (userToken, error) in
            guard error == nil else {
                print("error: \(String(describing: error))")
                DispatchQueue.main.async {
                    let alert = NewYorkAlertController(title: "Error", message: "you do not have an active apple music subscription", style: .alert)
                    
                    let cancel = NewYorkButton(title: "ok", style: .cancel)
                    
                    alert.addButton(cancel)
                    self.iTunesImage.removeFromSuperview()
                    self.chooseService.removeFromSuperview()
                    self.spotifyImage.removeFromSuperview()
                    self.iTunesButton.removeFromSuperview()
                    self.spotifyButton.removeFromSuperview()
                    self.continueButton.removeFromSuperview()
                    self.backButton.fadeOut()
                    self.currentStep = "choose_service"
                    self.present(alert, animated: true)
//                    self.addLoginPage1Elements()
//                    self.playVideo(from: "Mobile_Web_BG.m4v")
                }
                
                           return
                      }
              
            print("got user token: \(String(describing: userToken))")
            self.appleMusicAuthToken = userToken ?? ""
            musicRequest.addValue(self.appleMusicAuthToken , forHTTPHeaderField: "Music-User-Token")
            URLSession.shared.dataTask(with: musicRequest) { [self] (data, response, error) in
                guard error == nil else { return }
                if let json = try? JSON(data: data!) {
                    print(json)
                    if(json["data"].array != nil) {
                        //got return data
                        print("got data: \(String(describing: data))")
                        //use ID to show pop up to open in apple music
                        let id = json["data"]["id"].rawString()
                        //FINISH THIS PART
                        let appleMusicPublicURL = "music://\(id!)"
                        DispatchQueue.main.async {
                            self.backButton.isUserInteractionEnabled = true
                            self.transferButton.setTitle("finished transferring to itunes!", for: .normal)
    //                            self.transferButton.setTitle("finished transferring to spotify", for: .normal)
                            let alert = NewYorkAlertController(title: "Transfer Successful", message: "'\(self.playlistTitleLabel.text!)' finished transferring \(self.songQueue.count-1) songs", style: .alert)
                            
                            let cancel = NewYorkButton(title: "cancel", style: .cancel)
                            let openInSpotify = NewYorkButton(title: "open in itunes", style: .default) { _ in
    //                                print("Tapped OK")
                                if let url = URL(string: appleMusicPublicURL) {
                                    print("opening to \(url)")
                                    UIApplication.shared.open(url)
                                }
                            }
                            alert.addButton(cancel)
                            alert.addButton(openInSpotify)

                            self.present(alert, animated: true)
    //                            self.addLoginPage1Elements()
    // NOVEMBER 8th - LOGAN DEBUGGING STOPS HERE --------
                        }
                    }
                    
                    
                } else {
                    //                        lock.signal()
                }
            }.resume()
        }
        
    }
    func searchAppleMusic(searchTerm: String) {
        //you can change this to different countries
        let tmpStoreFront = "us"
        //            print("https://api.music.apple.com/v1/catalog/\(tmpStoreFront)/search?term=\((searchTerm.replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "") as! String)&types=playlists&limit=15")
        let musicURL = URL(string: "https://api.music.apple.com/v1/catalog/\(tmpStoreFront)/search?term=\((searchTerm.replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "") as! String)&types=playlists&limit=15")!
        //        print("requesting url: \(musicURL)")
        var musicRequest = URLRequest(url: musicURL)
        musicRequest.httpMethod = "GET"
        musicRequest.addValue("Bearer \(self.developerToken)", forHTTPHeaderField: "Authorization")
        //            musicRequest.addValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: musicRequest) { [self] (data, response, error) in
            guard error == nil else { return }
            if let json = try? JSON(data: data!) {
                //                            print(json)
                
                if((json["results"]["playlists"]["data"]).array != nil) {
                    self.appleMusicSearchResults.removeAll()
                    let result = (json["results"]["playlists"]["data"]).array!
                    for song in result {
                        let attributes = song["attributes"]
                        let currentSong = AppleMusicSong(id: attributes["playParams"]["id"].string ?? "", name: attributes["name"].string ?? "", artistName: attributes["curatorName"].string ?? "", artworkURL: attributes["artwork"]["url"].string ?? "", length:  TimeInterval(Double(0)))
                        //                            songs.append(currentSong)
                        self.appleMusicSearchResults.append(currentSong)
                    }
                    DispatchQueue.main.async {
                        self.searchResultsViewController.reloadData()
                        //                                    self.searchResultsViewController.fadeIn()
                    }
                }
                
                
            } else {
                //                        lock.signal()
            }
        }.resume()
        
        
    }
    func searchSpotify(query: String, type: IDCategory) {
        //INCLUDE ARTIST SO: GOOSEBUMPS TRAVIS SCOTT
        var returnVal: SpotifyWebAPI.Track!
        self.spotifySearchResults = []
        self.spotifySearchResults.removeAll()
        if(query != "") {
            self.spotify_anonymous.search(query: query, categories: [type], limit: 14)
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
        //                        spotify.playlistItems(uri as! SpotifyURIConvertible, limit: sear, offset: <#T##Int?#>, market: <#T##String?#>)
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
    func addSongToQueue(query: String, num: Int, outOf: Int) {
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
                    if(results.tracks!.items.isNotEmpty) {
                        let bestResult = results.tracks!.items[0]
                        //ADD SONG TO SONG QUEUE TO BE USED TO SAVE TO PLAYLIST
                        self.songQueue.append((bestResult.uri as! String) as! SpotifyURIConvertible)
                        DispatchQueue.main.async {
                            if let buttonTitle = self.transferButton.title(for: .normal) {
                                if(buttonTitle.contains("finish")) {
                                    
                                } else {
                                    self.transferButton.setTitle("transferring from \(self.transferringFrom) (\(self.songQueue.count-1)/\(outOf))", for: .normal)
                                }
                              }
                            
                        }
                        
                    } else {
                        //some shit not added
                    }
                    
                }
            ).store(in: &self.cancellables)
    }
    func getPlayListItemsFrom(uri: String, offset: Int?) {
        self.spotify_anonymous.playlistItems(uri as! SpotifyURIConvertible, limit: 100, offset: offset ?? 0).sink(
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
//                print(results)
                var songArr: [SpotifyURIConvertible] = []
//                print()
                for n in 0...results.items.count-1 {
                    //ADD EVERYSONG INTO AN ARRAY
                    songArr.append((results.items[n].item?.uri as! String) as! SpotifyURIConvertible)
                    
                    if(results.items[n].item?.type == .track) {
                        
                        self.playlistTracks.append(results.items[n].item!)
                    }
                    
                    
                }
                print(results.items[0])
                print("* total amount of songs loaded in playlist: \(songArr.count)")
//                self.addSongsToPlaylist(playlist: uri as! SpotifyURIConvertible, uris: songArr)
                
                if(results.next != nil) {
                    self.getPlayListItemsFrom(uri: uri, offset: (offset ?? 0)+100)
                } else {
                    DispatchQueue.main.async {
                        self.playlistContentsTableView.reloadData()
                        self.playlistContentsTableView.fadeIn()
                        self.transferButton.fadeIn()
                        self.transferButton.isUserInteractionEnabled = true
                    }
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
//                        self.addSongsToPlaylist(playlist: playlistURI, uris: ["spotify:track:51EC3I1nQXpec4gDk0mQyP","spotify:track:0FZ4Dmg8jJJAPJnvBIzD9z", "spotify:track:2BJSMvOGABRxokHKB0OI8i"])
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
    func addSongsToPlaylist(playlist: SpotifyURIConvertible, uris: [SpotifyURIConvertible], spotifypublicUrl: String) {
        self.spotify.addToPlaylist(playlist, uris: uris).sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                                    print("COULD NOT ADD SONGS TO PLAYLIST")
                                }
            },
            receiveValue: { results in
                print("* successfully added song to playlist!")
                DispatchQueue.main.async {
                    if(self.transferringFrom == "spotify") {
                        self.transferButton.setTitle("finished transferring to apple music", for: .normal)
                    } else {
                        
                        DispatchQueue.main.async {
                            self.backButton.isUserInteractionEnabled = true
                            self.transferButton.setTitle("finished transferring to spotify!", for: .normal)
//                            self.transferButton.setTitle("finished transferring to spotify", for: .normal)
                            let alert = NewYorkAlertController(title: "Transfer Successful", message: "'\(self.playlistTitleLabel.text!)' finished transferring \(self.songQueue.count-1) songs", style: .alert)
                            
                            let cancel = NewYorkButton(title: "cancel", style: .cancel)
                            let openInSpotify = NewYorkButton(title: "open in spotify", style: .default) { _ in
//                                print("Tapped OK")
                                if let url = URL(string: spotifypublicUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            alert.addButton(cancel)
                            alert.addButton(openInSpotify)

                            self.present(alert, animated: true)
//                            self.addLoginPage1Elements()
                        }
                    }
                    
                }
                
            }
        )
        .store(in: &self.cancellables)
    }
    func showSearchPart1() {
        //LOGAN HERE YOU CAN PUT YOUR UI
        currentStep = "search_1"
        webView.isHidden = true
        webView.alpha = 0
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
                self.searchBar.becomeFirstResponder()
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
    @objc func transferPressed(_ sender: UIButton) {
        print ("transfer button pressed")
        self.transferButton.setTitle("starting transfer...", for: .normal)
        transferButton.isUserInteractionEnabled = false
        self.backButton.isUserInteractionEnabled = false
        if(transferringFrom == "spotify") {
            var i = 0
            for trackz in self.playlistTracks {
                i=i+1
                searchAppleMusicForSong(searchTerm: trackz.name, trackNum: i, totalTracks: self.playlistTracks.count)
            }
            
        }
        else {
            DispatchQueue.main.async {
                self.songQueue.removeAll()
                var i = 0
                for song in self.appleMusicTracks {
    //                songQueue.append(song.uri as! SpotifyURIConvertible)
                    if(i != self.appleMusicTracks.count-1) {
                        
                        self.addSongToQueue(query: "\(song.name) \(song.artistName)", num: i, outOf: self.appleMusicTracks.count-1)
                        
                    } else {
                        self.spotify.search(query: "\(song.name) \(song.artistName)", categories: [.track])
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
                                    if(results.tracks!.items.isNotEmpty) {
                                        let bestResult = results.tracks!.items[0]
                                        //ADD SONG TO SONG QUEUE TO BE USED TO SAVE TO PLAYLIST
                                        self.songQueue.append((bestResult.uri as! String) as! SpotifyURIConvertible)
                                        DispatchQueue.main.async {
                                            self.transferButton.setTitle("finishing transfer...", for: .normal)
                                        }
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
                                                DispatchQueue.main.async {
                                                self.spotify.createPlaylist(for: user, PlaylistDetails(name: self.playlistTitleLabel.text ?? "", isPublic: true, isCollaborative: false, description: self.playlistDescription.text ?? "")).sink(
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
                                                        print("* playlist external url: \(results2.externalURLs!["spotify"])")
                                                        self.addSongsToPlaylist(playlist: playlistURI, uris: self.songQueue, spotifypublicUrl: results2.externalURLs!["spotify"]!.absoluteString as! String)
//                                                        print(results2)
//                                                        DispatchQueue.main.async {
//                                                            self.getData(from: URL(string: self.playlistCoverPhoto)!) { data, response, error in
//                                                                    guard let data = data, error == nil else { return }
//                                                                    print("Download Finished")
//                                                                    // always update the UI from the main thread
//                                                                    DispatchQueue.main.async() {
//                                                                        self.spotify.uploadPlaylistImage(playlistURI, imageData: Data(referencing: (self.playlistImage.image?.pngData()!) as! NSData) as! Data).sink(
//                                                                            receiveCompletion: { completion4 in
//                                                                //                    return completion
//                                                                                print("completion result: \(completion4)")
//                                                                                if case .failure(let error) = completion4 {
//                                                                                                    print("COULD NOT UPLOAD PLAYLIST COVER")
//                                                                                    print(error)
//                                                                                                }
//                                                                            },
//                                                                            receiveValue: { result3 in
//                                                                                print("* successfully added playlist art")
//                                                                                print(result3)
//
//                                                                            }
//                                                                        )
//                                                                            .store(in: &self.cancellables)
//                                                                    }
//                                                                }
//
//                                                        }
                                                        
                                                    }
                                                )
                                                .store(in: &self.cancellables)
                                                }
                                                
                                            }
                                        )
                                        .store(in: &self.cancellables)
                                    } else {
                                        //some shit not added
                                    }
                                    
                                }
                            ).store(in: &self.cancellables)
                        
                    }
                    i = i+1
                    
                }
                
            }
            
        }
    }
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
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
                self.appleMusicSearchResults.removeAll()
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
            
        } else if (currentStep == "transfer_page") {
            self.playlistImage.fadeOut()
            self.playlistAuthor.fadeOut()
            self.playlistDescription.fadeOut()
            self.playlistAuthorImage.fadeOut()
            self.playlistTitleLabel.fadeOut()
            searchBar.fadeIn()
            searchResultsViewController.fadeIn()
            playlistContentsTableView.fadeOut()
            transferButton.fadeOut()
            playlistTracks.removeAll()
            playlistContentsTableView.reloadData()
            currentStep = "search_1"
        }
        
    }
    @objc func iTunesPressed(_ sender: UIButton) {
        print("iTunes button pressed")
        iTunesImage.layer.borderColor = hexStringToUIColor(hex: "#cccccc").cgColor
        iTunesImage.layer.cornerRadius = iTunesImage.frame.width / 2
        iTunesImage.layer.borderWidth = 5
        spotifyImage.layer.borderWidth = 0
        transferringFrom = "spotify"
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
        transferringFrom = "itunes"
        
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
extension TimeInterval {
    var hourMinuteSecondMS: String {
        String(format:"%d:%02d:%02d.%03d", hour, minute, second, millisecond)
    }
    var minuteSecondMS: String {
//        String(format:"%d:%02d.%03d", minute, second, millisecond)
        String(format:"%d:%02d", minute, second)
    }
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}
extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
