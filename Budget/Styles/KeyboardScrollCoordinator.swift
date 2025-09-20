import SwiftUI
import Combine

@MainActor
final class KeyboardScrollCoordinator: ObservableObject {
    struct ActiveField {
        let id: String
        let accessoryHeight: CGFloat
    }

    nonisolated static let standardAccessoryHeight: CGFloat = 44
    nonisolated static let emojiAccessoryHeight: CGFloat = 44

    @Published private(set) var scrollOffset: CGFloat = 0

    private let basePadding: CGFloat
    private var keyboardHeight: CGFloat = 0
    private var buttonFrame: CGRect = .zero
    private var activeField: ActiveField?
    private var resetWorkItem: DispatchWorkItem?
    private var updateWorkItem: DispatchWorkItem?
    private var screenHeight: CGFloat = 0

    init(basePadding: CGFloat = 20) {
        self.basePadding = basePadding
    }

    func registerButtonFrame(_ frame: CGRect) {
        // Geometry readers report the already-shifted frame whenever the
        // scroll offset animates. Remove the temporary offset so we keep the
        // original anchor position of the button and avoid endless
        // recalculations while editing fields.
        let adjustedFrame = frame.offsetBy(dx: 0, dy: -scrollOffset)

        if buttonFrame == .zero {
            buttonFrame = adjustedFrame
            scheduleUpdate(delayed: true)
            return
        }

        guard !framesAreApproximatelyEqual(buttonFrame, adjustedFrame) else { return }

        buttonFrame = adjustedFrame
        scheduleUpdate(delayed: true)
    }

    func keyboardWillShow(height: CGFloat, in window: UIWindow? = nil) {
        keyboardHeight = height
        
        // Update screen height from window context if available, fallback to current screen
        if let window = window {
            screenHeight = window.screen.bounds.height
        } else if screenHeight == 0 {
            // Fallback: try to get any connected scene's screen
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                screenHeight = windowScene.screen.bounds.height
            } else {
                // Last resort fallback: Use a reasonable default for modern devices
                // This handles edge cases where no window scene is available
                screenHeight = 844 // iPhone 14/13/12 standard height
            }
        }
        
        scheduleUpdate(delayed: false)
    }

    func keyboardWillHide() {
        keyboardHeight = 0
        activeField = nil
        cancelResetWorkItem()
        cancelUpdateWorkItem()

        updateScrollOffsetIfNeeded(0)
    }

    func focusChanged(field id: String, isFocused: Bool, accessoryHeight: CGFloat = KeyboardScrollCoordinator.standardAccessoryHeight) {
        if isFocused {
            activeField = ActiveField(id: id, accessoryHeight: accessoryHeight)
            cancelResetWorkItem()
            scheduleUpdate(delayed: true)
        } else if activeField?.id == id {
            activeField = nil
            scheduleReset()
        }
    }

    private func scheduleUpdate(delayed: Bool) {
        cancelUpdateWorkItem()
        guard keyboardHeight > 0, buttonFrame != .zero, activeField != nil, screenHeight > 0 else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, let activeField = self.activeField else { return }

            let keyboardTop = self.screenHeight - self.keyboardHeight
            let target = keyboardTop - (self.basePadding + activeField.accessoryHeight)
            let buttonBottom = self.buttonFrame.maxY
            let offset = buttonBottom > target ? -(buttonBottom - target) : 0

            self.updateScrollOffsetIfNeeded(offset)
        }

        updateWorkItem = workItem
        let delay = delayed ? 0.05 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleReset() {
        cancelResetWorkItem()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeField == nil else { return }
            self.updateScrollOffsetIfNeeded(0)
        }

        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private func cancelResetWorkItem() {
        resetWorkItem?.cancel()
        resetWorkItem = nil
    }

    private func cancelUpdateWorkItem() {
        updateWorkItem?.cancel()
        updateWorkItem = nil
    }

    private func framesAreApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let threshold: CGFloat = 0.5
        return abs(lhs.minX - rhs.minX) < threshold &&
            abs(lhs.minY - rhs.minY) < threshold &&
            abs(lhs.maxX - rhs.maxX) < threshold &&
            abs(lhs.maxY - rhs.maxY) < threshold
    }

    private func updateScrollOffsetIfNeeded(_ newValue: CGFloat) {
        guard abs(newValue - scrollOffset) > 0.001 else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            scrollOffset = newValue
        }
    }
}

private struct KeyboardScrollCoordinatorKey: EnvironmentKey {
    static let defaultValue: KeyboardScrollCoordinator? = nil
}

extension EnvironmentValues {
    var keyboardScrollCoordinator: KeyboardScrollCoordinator? {
        get { self[KeyboardScrollCoordinatorKey.self] }
        set { self[KeyboardScrollCoordinatorKey.self] = newValue }
    }
}
