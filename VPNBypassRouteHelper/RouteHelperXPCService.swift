import Foundation

/// Owns the Mach `NSXPCListener` and vends `RouteHelperXPCResponder` to the app.
final class RouteHelperXPCListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: RouteHelperXPCProtocol.self)
        newConnection.exportedObject = RouteHelperXPCResponder()
        newConnection.resume()
        return true
    }
}

/// Executes JSON `RouteXPCRequestBody` and returns `RouteXPCResultBody` (same wire format as `PrivilegedHelperClient`).
final class RouteHelperXPCResponder: NSObject, RouteHelperXPCProtocol {
    func executeRequest(_ requestData: Data, withReply reply: @escaping (Data?, NSError?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: RouteXPCResultBody
            do {
                let req = try RouteXPCEncoder.decodeRequest(requestData)
                result = RouteHelperCommandHandler.run(request: req)
            } catch {
                result = .failure(message: error.localizedDescription, code: nil)
            }
            do {
                reply(try RouteXPCEncoder.encodeResult(result), nil)
            } catch {
                reply(nil, error as NSError)
            }
        }
    }
}
