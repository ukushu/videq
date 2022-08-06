//
//  Buttons.swift
//  PCam
//
//  Created by UKS on 06.08.2022.
//

import Foundation
import SwiftUI

extension TeleprompterView {
    func SpeedSlider() -> some View {
        HStack {
            Text(Image(systemName: "tortoise"))
            
            BoundsSlider(min: 0.7, max: 5, value: $telepVm.speed)
            
            Text(Image(systemName: "hare"))
        }
    }
    
    func BgOpacitySlider() -> some View {
        HStack {
            Text(Image(systemName: "sun.and.horizon.fill"))
            
            BoundsSlider(min: 0, max: 1, value: $telepVm.bgOpacity)
            
            Text(Image(systemName: "moon.stars.fill"))
        }
    }
    
    func TextSizeSlider() -> some View {
        HStack {
            Text("a")
                .font(.system(size: 20))
            
            BoundsSlider(min: 15, max: 45, value: $telepVm.textSize)
            
            Text("A")
                .font(.system(size: 20))
        }
    }
    
    func BtnSettings() -> some View {
        Button(action: { displaySettings.toggle() }) {
            Image(systemName: "gear")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.orange)
                .scaledToFit()
                .frame(width: 25, height: 25)
        }
    }
}

struct BtnReels: View {
    @EnvironmentObject var camera: CameraModel

    var body: some View {
        Button (action : { toggleRec() } ){
            Image(systemName: "video.and.waveform.fill")
                .resizable ()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .opacity(camera.isRecording ? 0: 1)
                .padding(12)
                .frame(width: 60, height: 60)
                .background{
                    Circle()
                        .stroke( camera.isRecording ? .clear : .red)
                }
                .padding(6)
                .background {
                    Circle()
                        .fill(camera.isRecording ? .red : .white)
                }
        }
    }

    func toggleRec() {
        if camera.isRecording {
            camera.stopRecording()
        } else {
            camera.startRecording()
        }
    }
}

struct BtnVideoPreview: View {
    @EnvironmentObject var camera: CameraModel

    var body: some View {
        if camera.recordedURLs.count > 0 {
            Button(action: { camera.showPreview.toggle() } ) {
                SuperBaseBtnLabel(text: "Preview", icon: "chevron.right")
                    .foregroundColor (.black)
                    .padding(.horizontal, 20)
                    .padding (.vertical,8)
                    .background{
                        Capsule()
                            .fill(Color.white)
                    }
            }
        }
    }
    
    func action() {
        camera.showPreview.toggle()
    }
}