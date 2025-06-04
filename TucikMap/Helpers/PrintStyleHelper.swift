//
//  PrintStyleHelper.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

class PrintStyleHelper {
    static func printNotUsedStyleToSee(detFeatureStyleData: DetFeatureStyleData) {
        if Settings.printNotUsedStyle {
            if Settings.filterNotUsedLayernName.isEmpty == false && detFeatureStyleData.layerName.contains(Settings.filterNotUsedLayernName) == false {
                return
            }
            print(detFeatureStyleData)
        }
    }
}
