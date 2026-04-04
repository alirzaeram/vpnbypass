import Foundation

/// Shared, synchronous process runner used by the app (`ScriptRunner`) and the privileged helper
/// so both invoke `bypass_routes.sh` the same way (no `osascript` in the helper).
enum RouteScriptProcessRunner {
    static func runBash(script: URL, arguments: [String]) throws -> (stdout: String, stderr: String, code: Int32) {
        try run(executable: URL(fileURLWithPath: "/bin/bash"), arguments: [script.path] + arguments)
    }

    static func run(executable: URL, arguments: [String]) throws -> (stdout: String, stderr: String, code: Int32) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        return (stdout, stderr, process.terminationStatus)
    }
}
