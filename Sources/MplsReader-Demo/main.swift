//
//  main.swift
//  BD_Chapters_MOD
//
//  Created by Kojirou on 2017/2/5.
//
//

import Foundation
import MplsReader

import MediaTools
let test = NewMkvmerge.init(
    global: .init(quiet: true, webm: false, title: "", defaultLanguage: nil),
    output: "output.mkv",
    inputs: [
        .init(file: "input.mkv", append: false,
              options: [
                .attachments(.none),
                .videoTracks(.disabledLANGS(["chi"])),
                .trackName(tid: 7, name: "")
        ]),
//        .init(file: <#T##String#>, append: <#T##Bool#>, options: <#T##[NewMkvmerge.Input.InputOption]#>)
])
print(test.arguments)
