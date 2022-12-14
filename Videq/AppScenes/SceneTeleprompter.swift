//
//  TelepromterView.swift
//  Videq
//
//  Created by UKS on 06.08.2022.
//

import Foundation
import SwiftUI

struct SceneTeleprompter: View {
    @ObservedObject var model = TeleprompterViewModel(miniMode: false)
    
    @State var delayedStartDialog: Bool = false
    
    @State var delayedStartTime: CGFloat = 3
    @State var delayedStartGoing: Bool = false
    
    var body: some View {
        ZStack {
            TeleprompterView(model: model)
                .teleprompterMaxi(height: UIScreen.screenHeight)
            
            HeaderBgLine()
            
            SettingsBtn()
            
            BackToMainMenuBtn(confirmationNeeded: false)
            
            if delayedStartGoing && !model.autoscrollIsGoing {
                DelayedStartTimeView(time: Int(delayedStartTime), mirror: model.mirrorYAxis)
            }
            
            VStack {
                Spacer()
                
                TeleprompterSettingsView(model: model)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $delayedStartDialog) {
            ConfigureDelayedStartView(dialogDisplayed: $delayedStartDialog, time: $delayedStartTime, delayedStartGoing: $delayedStartGoing)
        }
        .onAppear() {
            delayedStartRunner()
        }
    }
}

extension SceneTeleprompter {
    func SettingsBtn() -> some View {
        VStack {
            HStack {
                Spacer()
                
                if !model.autoscrollIsGoing {
                    TeleprompterDelayedStartBtn(show: $delayedStartDialog)
                        .padding(.trailing, 5)
                }
                
                TeleprompterSettingsBtn(displaySettings: $model.displaySettings)
                    .padding(.trailing, 15)
                    .padding(.top, 5)
            }
            Spacer()
        }
    }
}

///////////////////////////////
// DELAYED START
///////////////////////////////

extension SceneTeleprompter {
    func delayedStartRunner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard delayedStartGoing else { delayedStartRunner(); return }
            guard !model.autoscrollIsGoing else { delayedStartRunner(); self.delayedStartGoing = false; return }
                
            if delayedStartTime >= 1 {
                delayedStartTime -= 1
                
                if delayedStartTime < 1 {
                    self.delayedStartGoing = false
                    self.model.position.y -= CGFloat(30)
                    self.delayedStartTime = 3
                }
                
                print("\( Int(delayedStartTime) )")
            }
            
            delayedStartRunner()
        }
    }
}

fileprivate struct ConfigureDelayedStartView: View {
    @Binding var dialogDisplayed: Bool
    @Binding var time: CGFloat
    @Binding var delayedStartGoing: Bool
    
    init( dialogDisplayed: Binding<Bool>, time: Binding<CGFloat>, delayedStartGoing: Binding<Bool> ) {
        _dialogDisplayed = dialogDisplayed
        _time = time
        _delayedStartGoing = delayedStartGoing
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(Int(time))") + Text("sec")
            }
            .font(.system(size: 40))
            
            BoundsSlider(min: 3, max: 60, value: $time)
                .padding(50)
            
            HStack {
                //TODO: show only in horisontal mode
                Button(action: { dialogDisplayed = false; delayedStartGoing = false }) {
                    SuperBtnLabel(text: "Cancel", icon: "arrowshape.turn.up.backward.fill")
                }
                
                Button(action: { dialogDisplayed = false; delayedStartGoing = true }) {
                    SuperBtnLabel(text: "Start!", icon: "play.fill")
                }
            }
        }
    }
}

struct DelayedStartTimeView: View {
    let time: Int
    let mirror: Bool
    
    var body: some View {
        Text("\(time)")
            .font(.system(size: 150))
            .foregroundColor(.white)
            .background{
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
            }
            .if(mirror) { $0.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) }
    }
}
