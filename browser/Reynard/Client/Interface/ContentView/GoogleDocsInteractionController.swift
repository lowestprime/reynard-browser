//
//  GoogleDocsInteractionController.swift
//  Reynard
//

import GeckoView
import UIKit

@MainActor
final class GoogleDocsInteractionController: NSObject {
    private enum UX {
        static let verticalIntentRatio: CGFloat = 1.15
        static let minimumVelocity: CGFloat = 20
        static let minimumDelta: CGFloat = 0.25
    }

    private weak var session: GeckoSession?
    private var lastTranslation = CGPoint.zero
    private(set) var isEnabled = false
    private(set) var isKeyboardVisible = false

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

    func install(in contentView: ContentView) {
        contentView.addWebViewGestureRecognizer(panGestureRecognizer)
    }

    func update(session: GeckoSession?, url: String?) {
        let enabled = url.map {
            UserAgentPolicy().usesGoogleDocsDesktopCompatibility(for: $0)
        } ?? false

        if isEnabled, (!enabled || self.session !== session) {
            send(phase: .cancelled, location: .zero, deltaYRatio: 0)
        }

        self.session = session
        isEnabled = enabled && session != nil
        panGestureRecognizer.isEnabled = isEnabled
        lastTranslation = .zero
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
            send(phase: .began, location: location, deltaYRatio: 0)

        case .changed:
            let deltaY = translation.y - lastTranslation.y
            lastTranslation = translation
            guard abs(deltaY) >= UX.minimumDelta else { return }
            send(
                phase: .changed,
                location: location,
                deltaYRatio: -deltaY / view.bounds.height
            )

        case .ended:
            send(phase: .ended, location: location, deltaYRatio: 0)
            lastTranslation = .zero

        case .cancelled, .failed:
            send(phase: .cancelled, location: location, deltaYRatio: 0)
            lastTranslation = .zero

        default:
            break
        }
    }

    private func send(
        phase: GeckoSession.GoogleDocsPanPhase,
        location: CGPoint,
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
            deltaYRatio: deltaYRatio,
            keyboardVisible: isKeyboardVisible
        )
    }
}

extension GoogleDocsInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }

        let velocity = pan.velocity(in: pan.view)
        return abs(velocity.y) >= UX.minimumVelocity
            && abs(velocity.y) > abs(velocity.x) * UX.verticalIntentRatio
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
        otherGestureRecognizer is UILongPressGestureRecognizer
    }
}
