import SwiftUI
import Combine

@MainActor
final class KeyboardScrollCoordinator: ObservableObject {
    struct ActiveField {
        let id: String
        let accessoryHeight: CGFloat
    }

    static let standardAccessoryHeight: CGFloat = 44
    static let emojiAccessoryHeight: CGFloat = 56

    @Published private(set) var scrollOffset: CGFloat = 0

    private let basePadding: CGFloat
    private var keyboardHeight: CGFloat = 0
    private var buttonFrame: CGRect = .zero
    private var activeField: ActiveField?
    private var resetWorkItem: DispatchWorkItem?
    private var updateWorkItem: DispatchWorkItem?

    init(basePadding: CGFloat = 20) {
        self.basePadding = basePadding
    }

    func registerButtonFrame(_ frame: CGRect) {
        buttonFrame = frame
        scheduleUpdate(delayed: true)
    }

    func keyboardWillShow(height: CGFloat) {
        keyboardHeight = height
        scheduleUpdate(delayed: false)
    }

    func keyboardWillHide() {
        keyboardHeight = 0
        activeField = nil
        cancelResetWorkItem()
        cancelUpdateWorkItem()

        withAnimation(.easeInOut(duration: 0.3)) {
            scrollOffset = 0
        }
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
        guard keyboardHeight > 0, buttonFrame != .zero, activeField != nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, let activeField = self.activeField else { return }

            let keyboardTop = UIScreen.main.bounds.height - self.keyboardHeight
            let target = keyboardTop - (self.basePadding + activeField.accessoryHeight)
            let buttonBottom = self.buttonFrame.maxY
            let offset = buttonBottom > target ? -(buttonBottom - target) : 0

            withAnimation(.easeInOut(duration: 0.3)) {
                self.scrollOffset = offset
            }
        }

        updateWorkItem = workItem
        let delay = delayed ? 0.05 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleReset() {
        cancelResetWorkItem()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeField == nil else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.scrollOffset = 0
            }
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
