//
//  Extension.swift
//  PhotoBucket
//
//  Created by Augustine's MacBook on 5/11/20.
//  Copyright © 2020 Augustine. All rights reserved.
//
import UIKit
import GoogleSignIn
import Firebase
private class SaveAlertHandle {
    static var alertHandle: UIAlertController?
    
    class func set(_ handle: UIAlertController) {
        alertHandle = handle
    }
    
    class func clear() {
        alertHandle = nil
    }
    
    class func get() -> UIAlertController? {
        return alertHandle
    }
}

extension UIViewController {
    /*! @fn showMessagePrompt
     @brief Displays an alert with an 'OK' button and a message.
     @param message The message to display.
     */
    func showMessagePrompt(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: false, completion: nil)
    }
    
    /*! @fn showTextInputPromptWithMessage
     @brief Shows a prompt with a text field and 'OK'/'Cancel' buttons.
     @param message The message to display.
     @param completion A block to call when the user taps 'OK' or 'Cancel'.
     */
    func showTextInputPrompt(withMessage message: String,
                             completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let text = weakPrompt?.textFields?.first?.text else { return }
            completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
    }
    
    /*! @fn showSpinner
     @brief Shows the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func showSpinner(_ completion: (() -> Void)?) {
        let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                                preferredStyle: .alert)
        SaveAlertHandle.set(alertController)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = UIColor(ciColor: .black)
        spinner.center = CGPoint(x: alertController.view.frame.midX,
                                 y: alertController.view.frame.midY)
        spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                    .flexibleLeftMargin, .flexibleRightMargin]
        spinner.startAnimating()
        alertController.view.addSubview(spinner)
        present(alertController, animated: true, completion: completion)
    }
    
    /*! @fn hideSpinner
     @brief Hides the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func hideSpinner(_ completion: (() -> Void)?) {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            controller.dismiss(animated: true, completion: completion)
        }
    }
}

@IBDesignable class RoundButton: UIButton {
    // MARK: - Properties
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable var shadowColor: UIColor = UIColor.darkGray {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable var shadowOffsetWidth: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable var shadowOffsetHeight: CGFloat = 1.8 {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable var shadowOpacity: Float = 0.30 {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable var shadowRadius: CGFloat = 3.0 {
        didSet {
            setNeedsLayout()
        }
    }
    private var shadowLayer: CAShapeLayer = CAShapeLayer() {
        didSet {
            setNeedsLayout()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        shadowLayer.path = UIBezierPath(roundedRect: bounds,
                                        cornerRadius: cornerRadius).cgPath
        shadowLayer.fillColor = backgroundColor?.cgColor
        shadowLayer.shadowColor = shadowColor.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = CGSize(width: shadowOffsetWidth,
                                          height: shadowOffsetHeight)
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
        layer.insertSublayer(shadowLayer, at: 0)
    }
}

