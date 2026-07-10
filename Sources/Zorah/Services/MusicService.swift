import Foundation

actor MusicService {
    enum PlayerState: String {
        case playing
        case paused
        case stopped
        case unknown
    }

    func playerState() -> PlayerState {
        let result = runAppleScript(
            "tell application \"Music\" to return player state as text"
        )
        return PlayerState(rawValue: result.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .unknown
    }

    func play(playlist: String) {
        let script = """
        on run argv
            tell application "Music" to play playlist (item 1 of argv)
        end run
        """
        _ = runAppleScript(script, arguments: [playlist])
    }

    func pause() {
        _ = runAppleScript("tell application \"Music\" to pause")
    }

    func resume() {
        _ = runAppleScript("tell application \"Music\" to play")
    }

    private func runAppleScript(_ script: String, arguments: [String] = []) -> (output: String, status: Int32) {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script] + arguments
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return (String(decoding: data, as: UTF8.self), process.terminationStatus)
        } catch {
            return ("", -1)
        }
    }
}
