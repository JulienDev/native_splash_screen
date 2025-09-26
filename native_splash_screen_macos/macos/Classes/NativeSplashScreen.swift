import AppKit
import Cocoa

public class NativeSplashScreen {
    // MARK: - Public Configuration

    public static var configurationProvider: NativeSplashScreenConfigurationProvider?
    
    // MARK: - Private State

    private static var splashWindow: NSWindow?
    private static var isSplashShown: Bool = false
    
    // MARK: - Public Methods
    
    public static func show() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { show() }
            return
        }
        
        guard !isSplashShown else { return }
        
        guard let config = configurationProvider else {
            print("NativeSplashScreen: ERROR - ConfigurationProvider not set. Splash screen cannot be shown.")
            return
        }
        
        guard config.windowWidth > 0, config.windowHeight > 0 else {
            print("NativeSplashScreen: WARNING - Invalid window dimensions provided (<=0). Splash not shown.")
            return
        }
        
        let window = createSplashWindow(config: config)
        
        if let image = loadImageFromResources(config: config) {
            let imageView = createImageView(with: image, windowSize: window.frame.size)
            window.contentView?.addSubview(imageView)
        } else {
            print("NativeSplashScreen: WARNING - Failed to load image resources. Window will be blank.")
        }
        
        Self.splashWindow = window
        displaySplashWindow(window, animated: config.withAnimation)
        isSplashShown = true
    }
    
    public static func close(effect: String = "") {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { close(effect: effect) }
            return
        }
        
        guard isSplashShown, let window = splashWindow else { return }

        let fadeDuration = 0.3
        let slideDistance: CGFloat = 50.0
        
        let completionHandler = {
            window.orderOut(nil)
            Self.splashWindow = nil // Allow ARC to deallocate
            Self.isSplashShown = false
        }
        
        if effect.isEmpty {
            completionHandler()
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = fadeDuration
            switch effect.lowercased() {
            case "fade":
                window.animator().alphaValue = 0.0
            case "slide_up_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y += slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            case "slide_down_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y -= slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            default:
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: completionHandler)
    }
    
    // MARK: - Private Helper Methods

    private static func createSplashWindow(config: NativeSplashScreenConfigurationProvider) -> NSWindow {
        let contentRect = NSRect(x: 0, y: 0, width: CGFloat(config.windowWidth), height: CGFloat(config.windowHeight))
        
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.hasShadow = false
        window.title = config.windowTitle // Important for accessibility

        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let xPos = (screenRect.width - contentRect.width) / 2.0 + screenRect.origin.x
            let yPos = (screenRect.height - contentRect.height) / 2.0 + screenRect.origin.y
            window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
        
        // Always assign a new content view for custom drawing or subviews.
        window.contentView = NSView(frame: contentRect)
        return window
    }

    private static func createImageView(with image: NSImage, windowSize: NSSize) -> NSImageView {
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown // Sensible default

        let imageX = (windowSize.width - image.size.width) / 2.0
        let imageY = (windowSize.height - image.size.height) / 2.0
        
        imageView.frame = NSRect(x: imageX, y: imageY, width: image.size.width, height: image.size.height)
        return imageView
    }
    
    private static func displaySplashWindow(_ window: NSWindow, animated: Bool) {
        if animated {
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3 // Standard fade duration
                window.animator().alphaValue = 1.0
            }, completionHandler: nil)
        } else {
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
        }
    }

    private static func loadImageFromResources(config: NativeSplashScreenConfigurationProvider) -> NSImage? {
        let baseName = config.imageResourceName
        let baseExtension = config.imageResourceExtension

        guard !baseName.isEmpty else {
            print("NativeSplashScreen: ERROR - Missing image resource name in configuration.")
            return nil
        }

        guard let baseURL = Bundle.main.url(forResource: baseName, withExtension: baseExtension) else {
            print("NativeSplashScreen: ERROR - Unable to locate image resource \(baseName).\(baseExtension) in bundle.")
            return nil
        }

        guard let baseData = try? Data(contentsOf: baseURL),
              let baseRepresentation = NSBitmapImageRep(data: baseData) else {
            print("NativeSplashScreen: ERROR - Unable to decode image resource \(baseName).\(baseExtension).")
            return nil
        }

        let configuredWidth = CGFloat(max(config.imageWidth, 0))
        let configuredHeight = CGFloat(max(config.imageHeight, 0))
        let representationSize: NSSize
        if configuredWidth > 0.0 && configuredHeight > 0.0 {
            representationSize = NSSize(width: configuredWidth, height: configuredHeight)
        } else {
            representationSize = NSSize(width: CGFloat(baseRepresentation.pixelsWide), height: CGFloat(baseRepresentation.pixelsHigh))
        }

        baseRepresentation.size = representationSize

        let image = NSImage(size: representationSize)
        image.addRepresentation(baseRepresentation)

        if let retinaName = config.retinaImageResourceName {
            let retinaExtension = config.retinaImageResourceExtension ?? baseExtension
            if let retinaURL = Bundle.main.url(forResource: retinaName, withExtension: retinaExtension),
               let retinaData = try? Data(contentsOf: retinaURL),
               let retinaRepresentation = NSBitmapImageRep(data: retinaData) {
                retinaRepresentation.size = representationSize
                image.addRepresentation(retinaRepresentation)
            } else {
                print("NativeSplashScreen: WARNING - Unable to load retina image resource \(retinaName).\(retinaExtension). Using base representation only.")
            }
        }

        return image
    }
}
