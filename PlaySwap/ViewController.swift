//
//  ViewController.swift
//  PlaySwap
//
//  Created by Jordan Wood on 10/4/21.
//

import UIKit
import AnimatedGradientView

class ViewController: UIViewController {
    var iTunesImage = UIImageView()
    var emailField = UITextField()
    var passwordField = UITextField()
    
    var loginButton = UIButton()
    
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
        
        //Looks for single or multiple taps.
             let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            //tap.cancelsTouchesInView = false

            view.addGestureRecognizer(tap)
    }
    func loginPressed() {
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
