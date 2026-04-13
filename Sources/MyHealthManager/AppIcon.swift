import AppKit

enum AppIconFactory {
  static func makeAppIcon(size: CGFloat = 512) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let basePath = NSBezierPath(roundedRect: bounds, xRadius: size * 0.24, yRadius: size * 0.24)
    NSColor(calibratedRed: 0.95, green: 0.70, blue: 0.54, alpha: 1).setFill()
    basePath.fill()

    let haloPath = NSBezierPath(ovalIn: NSRect(x: size * 0.14, y: size * 0.18, width: size * 0.72, height: size * 0.64))
    NSColor(calibratedRed: 0.99, green: 0.87, blue: 0.76, alpha: 1).setFill()
    haloPath.fill()

    let ringRect = NSRect(x: size * 0.18, y: size * 0.18, width: size * 0.64, height: size * 0.64)
    let ringPath = NSBezierPath(ovalIn: ringRect)
    ringPath.lineWidth = size * 0.045
    NSColor(calibratedRed: 0.63, green: 0.28, blue: 0.20, alpha: 1).setStroke()
    ringPath.stroke()

    let heart = NSBezierPath()
    heart.move(to: NSPoint(x: size * 0.50, y: size * 0.30))
    heart.curve(
      to: NSPoint(x: size * 0.27, y: size * 0.53),
      controlPoint1: NSPoint(x: size * 0.36, y: size * 0.39),
      controlPoint2: NSPoint(x: size * 0.27, y: size * 0.42)
    )
    heart.curve(
      to: NSPoint(x: size * 0.39, y: size * 0.68),
      controlPoint1: NSPoint(x: size * 0.27, y: size * 0.61),
      controlPoint2: NSPoint(x: size * 0.32, y: size * 0.68)
    )
    heart.curve(
      to: NSPoint(x: size * 0.50, y: size * 0.60),
      controlPoint1: NSPoint(x: size * 0.45, y: size * 0.68),
      controlPoint2: NSPoint(x: size * 0.48, y: size * 0.64)
    )
    heart.curve(
      to: NSPoint(x: size * 0.61, y: size * 0.68),
      controlPoint1: NSPoint(x: size * 0.52, y: size * 0.64),
      controlPoint2: NSPoint(x: size * 0.55, y: size * 0.68)
    )
    heart.curve(
      to: NSPoint(x: size * 0.73, y: size * 0.53),
      controlPoint1: NSPoint(x: size * 0.68, y: size * 0.68),
      controlPoint2: NSPoint(x: size * 0.73, y: size * 0.61)
    )
    heart.curve(
      to: NSPoint(x: size * 0.50, y: size * 0.30),
      controlPoint1: NSPoint(x: size * 0.73, y: size * 0.42),
      controlPoint2: NSPoint(x: size * 0.64, y: size * 0.39)
    )
    NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.95, alpha: 1).setFill()
    heart.fill()

    let pulse = NSBezierPath()
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    pulse.lineWidth = size * 0.042
    pulse.move(to: NSPoint(x: size * 0.28, y: size * 0.44))
    pulse.line(to: NSPoint(x: size * 0.39, y: size * 0.44))
    pulse.line(to: NSPoint(x: size * 0.45, y: size * 0.54))
    pulse.line(to: NSPoint(x: size * 0.54, y: size * 0.35))
    pulse.line(to: NSPoint(x: size * 0.60, y: size * 0.44))
    pulse.line(to: NSPoint(x: size * 0.72, y: size * 0.44))
    NSColor(calibratedRed: 0.84, green: 0.35, blue: 0.24, alpha: 1).setStroke()
    pulse.stroke()

    let sparkColor = NSColor(calibratedRed: 1.0, green: 0.89, blue: 0.56, alpha: 1)
    for point in [
      NSPoint(x: size * 0.24, y: size * 0.75),
      NSPoint(x: size * 0.77, y: size * 0.72),
      NSPoint(x: size * 0.72, y: size * 0.24),
    ] {
      let spark = NSBezierPath()
      spark.lineCapStyle = .round
      spark.lineWidth = size * 0.024
      spark.move(to: NSPoint(x: point.x, y: point.y - size * 0.035))
      spark.line(to: NSPoint(x: point.x, y: point.y + size * 0.035))
      spark.move(to: NSPoint(x: point.x - size * 0.035, y: point.y))
      spark.line(to: NSPoint(x: point.x + size * 0.035, y: point.y))
      sparkColor.setStroke()
      spark.stroke()
    }

    image.unlockFocus()
    image.isTemplate = false
    return image
  }

  static func makeStatusBarIcon() -> NSImage {
    let size: CGFloat = 18
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let circle = NSBezierPath(ovalIn: NSRect(x: 2.1, y: 2.1, width: 13.8, height: 13.8))
    circle.lineWidth = 1.4
    NSColor.labelColor.setStroke()
    circle.stroke()

    let pulse = NSBezierPath()
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    pulse.lineWidth = 1.45
    pulse.move(to: NSPoint(x: 4.2, y: 8.9))
    pulse.line(to: NSPoint(x: 6.3, y: 8.9))
    pulse.line(to: NSPoint(x: 7.2, y: 11.0))
    pulse.line(to: NSPoint(x: 9.2, y: 6.0))
    pulse.line(to: NSPoint(x: 10.6, y: 9.6))
    pulse.line(to: NSPoint(x: 13.8, y: 9.6))
    pulse.stroke()

    let spark = NSBezierPath()
    spark.lineCapStyle = .round
    spark.lineWidth = 1.2
    spark.move(to: NSPoint(x: 13.0, y: 12.6))
    spark.line(to: NSPoint(x: 13.0, y: 14.6))
    spark.move(to: NSPoint(x: 12.0, y: 13.6))
    spark.line(to: NSPoint(x: 14.0, y: 13.6))
    spark.stroke()

    image.unlockFocus()
    image.isTemplate = true
    return image
  }
}
