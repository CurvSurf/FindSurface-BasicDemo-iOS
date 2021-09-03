//
//  ContentView.swift
//  FindSurfaceiOS
//
//  Created by CurvSurf MacBook Pro on 2021/08/17.
//

import SwiftUI

struct ContentView: View {
    
    #if !targetEnvironment(simulator)
    init() {
        // This function will be invoked once
        // right before the app starts running.
        runFindSurfaceDemo(NORMAL_PRESET_LIST,
                           SMART_PRESET_LIST,
                           POINTS)
    }
    #endif
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                Label(
                    title: { Text("FindSurface Basic Demo").font(.title) },
                    icon: { Image(uiImage: UIImage(named: "AppIcon") ?? UIImage()) }
                )
                Spacer()
            }
            
            HStack {
                Text("The input point cloud of this application looks like as follows: ")
                Spacer()
            }
            
            Image("sample_pc")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            
            Text("TL;DR. Look at the console to see the actual result.").bold().padding(.bottom, 5)
            
            Text("This demo project demonstrates a textual example of how to use FindSurface APIs in the source code.").padding(.bottom, 5)
            
            Text("This application attempts to search specific geometry shapes in the point cloud by using FindSurface APIs. The result will be printed in a debug console after the application begins.")
            
            Spacer()
            
        }.padding(16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
