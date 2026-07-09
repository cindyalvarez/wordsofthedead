import SwiftUI
import AppKit

@main
struct WordsOfTheDeadApp: App {
    @StateObject private var engine = GameEngine()
    @StateObject private var notifications = NotificationManager.shared

    private var qaMode: Bool { CommandLine.arguments.contains("--qa") }

    var body: some Scene {
        WindowGroup("Words of the Dead") {
            Group {
                if qaMode {
                    QAReviewView()
                        .frame(minWidth: 900, minHeight: 700)
                } else {
                    GameView(engine: engine)
                        .frame(minWidth: 1200, minHeight: 900)
                }
            }
            .onAppear {
                NSApplication.shared.setActivationPolicy(.regular)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        .defaultSize(width: 1320, height: 1000)
        .windowResizability(.contentMinSize)
    }
}
