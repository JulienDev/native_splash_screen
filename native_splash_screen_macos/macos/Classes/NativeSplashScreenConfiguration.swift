public protocol NativeSplashScreenConfigurationProvider {
    // Window Properties
    var windowWidth: Int { get }
    var windowHeight: Int { get }
    var windowTitle: String { get }

    // Animation Properties
    var withAnimation: Bool { get }

    // Image Properties
    var imagePixels: [UInt8] { get }
    var imageResourceName: String { get }
    var imageResourceExtension: String { get }
    var retinaImageResourceName: String? { get }
    var retinaImageResourceExtension: String? { get }
    var imageWidth: Int { get }
    var imageHeight: Int { get }
}

public extension NativeSplashScreenConfigurationProvider {
    var imagePixels: [UInt8] { [] }

    var imageResourceName: String { "" }
    var imageResourceExtension: String { "" }

    var retinaImageResourceName: String? { nil }
    var retinaImageResourceExtension: String? { nil }
}
