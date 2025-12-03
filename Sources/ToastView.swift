import SwiftUI

/// A toast notification view that appears temporarily
struct ToastView: View {
    let message: String
    let icon: String
    let duration: TimeInterval
    @Binding var isShowing: Bool
    
    @State private var opacity: Double = 0
    
    init(message: String, icon: String = "checkmark.circle.fill", duration: TimeInterval = 2.0, isShowing: Binding<Bool>) {
        self.message = message
        self.icon = icon
        self.duration = duration
        self._isShowing = isShowing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.85))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
    }
}

/// Toast modifier for easy use
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    Spacer()
                    ToastView(message: message, icon: icon, duration: duration, isShowing: $isShowing)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, icon: icon, duration: duration))
    }
}

/// Toast manager for showing toasts from anywhere
@MainActor
class ToastManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var message: String = ""
    @Published var icon: String = "checkmark.circle.fill"
    
    static let shared = ToastManager()
    
    private init() {}
    
    func show(message: String, icon: String = "checkmark.circle.fill") {
        self.message = message
        self.icon = icon
        self.isShowing = true
    }
    
    func showSuccess(_ message: String) {
        show(message: message, icon: "checkmark.circle.fill")
    }
    
    func showError(_ message: String) {
        show(message: message, icon: "exclamationmark.circle.fill")
    }
    
    func showInfo(_ message: String) {
        show(message: message, icon: "info.circle.fill")
    }
}
