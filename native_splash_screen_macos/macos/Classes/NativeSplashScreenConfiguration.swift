public protocol NativeSplashScreenConfigurationProvider {
    // Window Properties
    var windowWidth: Int { get }
    var windowHeight: Int { get }
    var windowTitle: String { get }

    // Animation Properties
    var withAnimation: Bool { get }

    // Image Properties
    var imageResourceName: String { get }
    var imageResourceExtension: String { get }
    var retinaImageResourceName: String? { get }
    var retinaImageResourceExtension: String? { get }
    var imageWidth: Int { get }
    var imageHeight: Int { get }
}
