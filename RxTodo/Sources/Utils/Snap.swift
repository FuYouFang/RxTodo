//
//  CeilUtil.swift
//  StyleShare
//
//  Created by 전수열 on 8/27/15.
//  Copyright (c) 2015 StyleShare Inc. All rights reserved.
//

import UIKit

/// Ceil to snap pixel
func snap(_ x: CGFloat) -> CGFloat {
    let scale = UIScreen.main.scale
    // 返回不小于value 的下一个整数
    // x 0.5
    // ceil(0.5 * 3) / 3
    // 2 / 3
    return ceil(x * scale) / scale
}

func snap(_ point: CGPoint) -> CGPoint {
    return CGPoint(x: snap(point.x), y: snap(point.y))
}

func snap(_ size: CGSize) -> CGSize {
    return CGSize(width: snap(size.width), height: snap(size.height))
}

func snap(_ rect: CGRect) -> CGRect {
    return CGRect(origin: snap(rect.origin), size: snap(rect.size))
}
