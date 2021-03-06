import UIKit

class ScreenSizeCompatibleLayoutConstraint: NSLayoutConstraint {
    
    @IBInspectable var inch3_5: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch3_5, value: inch3_5)
        }
    }
    
    @IBInspectable var inch4: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch4, value: inch4)
        }
    }
    
    @IBInspectable var inch4_7: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch4_7, value: inch4_7)
        }
    }
    
    @IBInspectable var inch5_5: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch5_5, value: inch5_5)
        }
    }
    
    @IBInspectable var inch5_8: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch5_8, value: inch5_8)
        }
    }
    
    @IBInspectable var inch6_1: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch6_1, value: inch6_1)
        }
    }
    
    @IBInspectable var inch6_5: CGFloat = 0 {
        didSet {
            updateConstraint(trait: .inch6_5, value: inch6_5)
        }
    }
    
    private func updateConstraint(trait: ScreenSize, value: CGFloat) {
        guard trait == ScreenSize.current else {
            return
        }
        constant = value
    }
    
}
