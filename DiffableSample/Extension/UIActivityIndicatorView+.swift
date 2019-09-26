//
//  UIActivityIndicatorView+.swift
//  DiffableSample
//
//  Created by 長田卓馬 on 2019/09/25.
//  Copyright © 2019 Takuma Osada. All rights reserved.
//

import UIKit

extension UIActivityIndicatorView {
    var animatable: Bool  {
        set {
            if (newValue) {
                startAnimating()
            } else {
                stopAnimating()
            }
        }

        get {
            return isAnimating
        }
    }
}
