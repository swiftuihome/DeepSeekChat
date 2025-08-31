import AVFoundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum AIProxy {
    /// The current sdk version
    public static let sdkVersion = "0.126.0"
    
    /// AIProxy's DeepSeek service
    ///
    /// - Parameters:
    ///   - partialKey: Your partial key is displayed in the AIProxy dashboard when you submit your DeepSeek key.
    ///     AIProxy takes your DeepSeek key, encrypts it, and stores part of the result on our servers. The part that you include
    ///     here is the other part. Both pieces are needed to decrypt your key and fulfill the request to DeepSeek.
    ///
    ///   - serviceURL: The service URL is displayed in the AIProxy dashboard when you submit your DeepSeek key.
    ///
    ///   - clientID: An optional clientID to attribute requests to specific users or devices. It is OK to leave this blank for
    ///     most applications. You would set this if you already have an analytics system, and you'd like to annotate AIProxy
    ///     requests with IDs that are known to other parts of your system.
    ///
    ///     If you do not supply your own clientID, the internals of this lib will generate UUIDs for you. The default UUIDs are
    ///     persistent on macOS and can be accurately used to attribute all requests to the same device. The default UUIDs
    ///     on iOS are pesistent until the end user chooses to rotate their vendor identification number.
    ///
    /// - Returns: An instance of DeepSeekService configured and ready to make requests
//    public static func deepSeekService(
//        partialKey: String,
//        serviceURL: String,
//        clientID: String? = nil
//    ) -> DeepSeekService {
//        return DeepSeekProxiedService(
//            partialKey: partialKey,
//            serviceURL: serviceURL,
//            clientID: clientID
//        )
//    }

    /// Service that makes request directly to DeepSeek. No protections are built-in for this service.
    /// Please only use this for BYOK use cases.
    ///
    /// - Parameters:
    ///   - unprotectedAPIKey: Your DeepSeek API key
    /// - Returns: An instance of  DeepSeek configured and ready to make requests
    public static func deepSeekDirectService(
        unprotectedAPIKey: String,
        baseURL: String? = nil
    ) -> DeepSeekService {
        return DeepSeekDirectService(
            unprotectedAPIKey: unprotectedAPIKey,
            baseURL: baseURL
        )
    }
    
    /// Returns a URLSession for communication with AIProxy.
    public static func session() -> URLSession {
        return AIProxyURLSession.create()
    }
}
