//
//  GoogleDocsInteractionController.swift
//  Reynard
//

import GeckoView
import UIKit

@MainActor
final class GoogleDocsInteractionController: NSObject {
    private enum UX {
        static let axisIntentRatio: CGFloat = 1.12
        static let minimumVelocity: CGFloat = 20
        static let minimumDelta: CGFloat = 0.25
        static let longPressDuration: TimeInterval = 0.48
        static let longPressMovement: CGFloat = 12
        static let commandAnchorSize = CGSize(width: 1, height: 1)
    }

    private weak var session: GeckoSession?
    private weak var commandAnchorContainer: UIView?
    private var lastTranslation = CGPoint.zero
    private var basePinchZoomLevel = PageZoomLevels.defaultLevel
    private var currentPageZoomLevel = PageZoomLevels.defaultLevel
    private(set) var isEnabled = false
    private(set) var isKeyboardVisible = false

    var onPageZoomLevelChange: ((Int) -> Void)?

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 1
        recognizer.cancelsTouchesInView = true
        recognizer.delaysTouchesBegan = true
        recognizer.delegate = self
        recognizer.isEnabled = false
        return recognizer
    }()

    private lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = {
        let recognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        recognizer.cancelsTouchesInView = true
        recognizer.delaysTouchesBegan = true
        recognizer.delegate = self
        recognizer.isEnabled = false
        return recognizer
    }()

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recognizer.minimumPressDuration = UX.longPressDuration
        recognizer.allowableMovement = UX.longPressMovement
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self
        recognizer.isEnabled = false
        return recognizer
    }()

    private lazy var commandTargetView: GoogleDocsCommandTargetView = {
        let view = GoogleDocsCommandTargetView()
        view.backgroundColor = .clear
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        view.accessibilityIdentifier = "GoogleDocsHorizontalPinchContextMenuClipboardMarkdownCompatibility"
        view.onCommand = { [weak self] command, text in
            self?.sendClipboardCommand(command, text: text)
        }
        return view
    }()

    func install(in contentView: ContentView) {
        contentView.addWebViewGestureRecognizer(panGestureRecognizer)
        contentView.addWebViewGestureRecognizer(pinchGestureRecognizer)
        contentView.addWebViewGestureRecognizer(longPressGestureRecognizer)
        contentView.addSubview(commandTargetView)
        commandAnchorContainer = contentView
    }

    func update(session: GeckoSession?, url: String?, pageZoomLevel: Int) {
        let enabled = url.map {
            UserAgentPolicy().usesGoogleDocsDesktopCompatibility(for: $0)
        } ?? false

        if isEnabled, (!enabled || self.session !== session) {
            send(phase: .cancelled, location: .zero, deltaXRatio: 0, deltaYRatio: 0)
        }

        self.session = session
        currentPageZoomLevel = pageZoomLevel
        isEnabled = enabled && session != nil
        panGestureRecognizer.isEnabled = isEnabled
        pinchGestureRecognizer.isEnabled = isEnabled
        longPressGestureRecognizer.isEnabled = isEnabled
        lastTranslation = .zero
        if !isEnabled {
            UIMenuController.shared.hideMenu()
            UIMenuController.shared.menuItems = nil
            commandTargetView.resignFirstResponder()
        }
    }

    func setKeyboardVisible(_ visible: Bool) {
        isKeyboardVisible = visible
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard isEnabled,
              let view = recognizer.view,
              view.bounds.width > 1,
              view.bounds.height > 1 else {
            return
        }

        let location = recognizer.location(in: view)
        let translation = recognizer.translation(in: view)
        switch recognizer.state {
        case .began:
            lastTranslation = translation
            send(phase: .began, location: location, deltaXRatio: 0, deltaYRatio: 0)

        case .changed:
            let deltaX = translation.x - lastTranslation.x
            let deltaY = translation.y - lastTranslation.y
            lastTranslation = translation
            guard abs(deltaX) >= UX.minimumDelta || abs(deltaY) >= UX.minimumDelta else { return }
            send(
                phase: .changed,
                location: location,
                deltaXRatio: -deltaX / view.bounds.width,
                deltaYRatio: -deltaY / view.bounds.height
            )

        case .ended:
            send(phase: .ended, location: location, deltaXRatio: 0, deltaYRatio: 0)
            lastTranslation = .zero

        case .cancelled, .failed:
            send(phase: .cancelled, location: location, deltaXRatio: 0, deltaYRatio: 0)
            lastTranslation = .zero

        default:
            break
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard isEnabled else { return }

        switch recognizer.state {
        case .began:
            basePinchZoomLevel = currentPageZoomLevel

        case .changed:
            let level = PageZoomLevels.level(from: basePinchZoomLevel, scale: recognizer.scale)
            guard level != currentPageZoomLevel else { return }
            currentPageZoomLevel = level
            onPageZoomLevelChange?(level)

        case .ended, .cancelled, .failed:
            basePinchZoomLevel = currentPageZoomLevel

        default:
            break
        }
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard isEnabled,
              recognizer.state == .began,
              let view = recognizer.view else {
            return
        }

        let location = recognizer.location(in: view)
        sendContextMenu(location: location)
        presentCommandMenu(at: location, from: view)
    }

    private func send(
        phase: GeckoSession.GoogleDocsPanPhase,
        location: CGPoint,
        deltaXRatio: CGFloat,
        deltaYRatio: CGFloat
    ) {
        guard let session,
              let view = panGestureRecognizer.view,
              view.bounds.width > 1,
              view.bounds.height > 1 else {
            return
        }

        session.handleGoogleDocsPan(
            phase: phase,
            xRatio: min(max(location.x / view.bounds.width, 0), 1),
            yRatio: min(max(location.y / view.bounds.height, 0), 1),
            deltaXRatio: deltaXRatio,
            deltaYRatio: deltaYRatio,
            keyboardVisible: isKeyboardVisible
        )
    }

    private func sendContextMenu(location: CGPoint) {
        guard let session,
              let view = longPressGestureRecognizer.view,
              view.bounds.width > 1,
              view.bounds.height > 1 else {
            return
        }

        session.handleGoogleDocsContextMenu(
            xRatio: min(max(location.x / view.bounds.width, 0), 1),
            yRatio: min(max(location.y / view.bounds.height, 0), 1),
            keyboardVisible: isKeyboardVisible
        )
    }

    private func sendClipboardCommand(_ command: GeckoSession.GoogleDocsClipboardCommand, text: String?) {
        guard isEnabled else { return }
        session?.handleGoogleDocsClipboardCommand(command, text: text)
    }

    private func presentCommandMenu(at location: CGPoint, from sourceView: UIView) {
        guard let container = commandAnchorContainer else { return }

        let anchorPoint = sourceView.convert(location, to: container)
        commandTargetView.frame = CGRect(origin: anchorPoint, size: UX.commandAnchorSize)
        commandTargetView.becomeFirstResponder()

        let menu = UIMenuController.shared
        menu.menuItems = [
            UIMenuItem(
                title: "Copy",
                action: #selector(GoogleDocsCommandTargetView.copyGoogleDocsSelection(_:))
            ),
            UIMenuItem(
                title: "Paste",
                action: #selector(GoogleDocsCommandTargetView.pasteGoogleDocsText(_:))
            ),
            UIMenuItem(
                title: "Paste Markdown",
                action: #selector(GoogleDocsCommandTargetView.pasteGoogleDocsMarkdown(_:))
            ),
        ]
        menu.showMenu(from: commandTargetView, rect: commandTargetView.bounds)
    }
}

extension GoogleDocsInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled else {
            return false
        }

        if gestureRecognizer is UIPinchGestureRecognizer {
            return true
        }

        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        }

        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }

        let velocity = pan.velocity(in: pan.view)
        let absX = abs(velocity.x)
        let absY = abs(velocity.y)
        let dominantVelocity = max(absX, absY)
        let crossAxisVelocity = min(absX, absY)
        return dominantVelocity >= UX.minimumVelocity
            && dominantVelocity > crossAxisVelocity * UX.axisIntentRatio
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UILongPressGestureRecognizer
    }
}

private final class GoogleDocsCommandTargetView: UIView {
    var onCommand: ((GeckoSession.GoogleDocsClipboardCommand, String?) -> Void)?

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copyGoogleDocsSelection(_:)):
            return true
        case #selector(pasteGoogleDocsText(_:)), #selector(pasteGoogleDocsMarkdown(_:)):
            return UIPasteboard.general.hasStrings
        default:
            return false
        }
    }

    @objc func copyGoogleDocsSelection(_ sender: Any?) {
        onCommand?(.copy, nil)
        finishCommand()
    }

    @objc func pasteGoogleDocsText(_ sender: Any?) {
        onCommand?(.pastePlainText, UIPasteboard.general.string)
        finishCommand()
    }

    @objc func pasteGoogleDocsMarkdown(_ sender: Any?) {
        onCommand?(.pasteMarkdown, UIPasteboard.general.string)
        finishCommand()
    }

    private func finishCommand() {
        UIMenuController.shared.hideMenu()
        UIMenuController.shared.menuItems = nil
        resignFirstResponder()
    }
}
