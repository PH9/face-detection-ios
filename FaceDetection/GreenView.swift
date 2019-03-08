import UIKit

class GreenView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
    layer.borderWidth = 1.0
    layer.cornerRadius = 4.0
  }

  func show(at rect: CGRect) {
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.2) {
        self.alpha = 1.0
        self.frame = rect
      }
    }
  }

  func hide() {
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.2) {
        self.alpha = 0.0
      }
    }
  }
}
