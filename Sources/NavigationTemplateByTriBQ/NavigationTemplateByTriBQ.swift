import SwiftUI

public protocol Pushable: Identifiable, Equatable, Hashable {}
public protocol Presentable: Identifiable, Equatable, Hashable {}

/// Base for all Navigator
///
///  A Navigator base, each navigation stack should only have 1 Navigator.
///
///  This should declared as a `EnvironmentObject`,  All child view can have to it's stack's navigator.
open class Navigator<
    PushableTemplate: Pushable,
    PresentableTemplate: Presentable
>: ObservableObject {
    public init() {}

    /// Navigation Stack
    ///
    /// This represent the navigation stack, top view will be the last element of array
    @Published
    public var navigationStack: [PushableTemplate] = []

    /// Presenting view
    ///
    ///  only 1 view can be presented at any time
    @Published
    public var presentable: PresentableTemplate? = nil

    /// Full screen present view
    ///
    ///  Element in this array will be present  as full screen cover
    open var fullScreenPresentables: [PresentableTemplate] { [] }

    /// Modal present view
    ///
    ///  Element in this array will be present  as modal
    open var modalPresentables: [PresentableTemplate] { [] }

    /// Push to new view
    ///
    /// equivalent of `UINavigationController.pushViewController(_:animated:)`
    public func push(to pushable: PushableTemplate) {
        self.navigationStack.append(pushable)
    }

    /// Pop to last view
    ///
    /// equivalent of `UINavigationController.popViewController()`
    public func pop() {
        _ = navigationStack.removeLast()
    }

    /// Pop to root view
    ///
    /// equivalent of `UINavigationController.popToRootViewController(animated:)`
    public func popToRoot() {
        navigationStack = []
    }


    /// Present a new view
    ///
    /// equivalent of `present(_:animated:completion:)`
    public func present(_ presentable: PresentableTemplate) {
        self.presentable = presentable
    }

    /// Check function
    ///
    ///  To determine if need to use `fullScreenCover`
    public func isFullScreenCover() -> Binding<Bool> {
        guard let presentable = presentable else { return .constant(false) }
        return .constant(fullScreenPresentables.contains(presentable))
    }

    /// Check function
    ///
    ///  To determine if need to use `sheet`
    public func isModal() -> Binding<Bool> {
        guard let presentable = presentable else { return .constant(false) }
        return .constant(modalPresentables.contains(presentable))
    }

    /// Dismiss
    ///
    /// equivalent of `dismiss(animated:completion:)`
    public func dismiss() {
        self.presentable = nil
    }
}

/// `NavigationControllerView` is equivalent of UINavigationController.
///
/// Use this to construct your navigation stack, use in your root view.
///
/// When present a new modal view, make sure to create a new navigation stack for that view.
///
/// Each view of TabBar should be a navigation stack of it own.
///
/// - Parameter navigator: an instance of type `Navigator`. this will become a `EnvironmentObject`, allow all child view to access this navigator and use this to navigate through the navigation stack
/// - Parameter content: Root view
/// - Parameter pushDestination: Destination when use `Navigator.push(to:)`, equivalent of `pushViewController(_:animated:)`
/// - Parameter presentDestination: Destination when use `Navigator.present(_:)`, equivalent of `present(_:animated:completion:)`
/// - Returns: a view
public struct NavigationControllerView<
    Content: View,
    PushDestination: View,
    PresentDestination: View,
    PushableTemplate: Pushable,
    PresentableTemplate: Presentable
>: View {
    public init(
        navigator: Navigator<PushableTemplate, PresentableTemplate>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder pushDestination: @escaping (PushableTemplate) -> PushDestination,
        @ViewBuilder presentDestination: @escaping (PresentableTemplate) -> PresentDestination
    ) {
        self.content = content
        self.navigator = navigator
        self.pushDestination = pushDestination
        self.presentDestination = presentDestination
    }


    @ViewBuilder
    let content: () -> Content

    @ViewBuilder
    let pushDestination: (PushableTemplate) -> PushDestination

    @ViewBuilder
    let presentDestination: (PresentableTemplate) -> PresentDestination

    @ObservedObject
    private var navigator: Navigator<PushableTemplate, PresentableTemplate>

    public var body: some View {
        NavigationStack(path: $navigator.navigationStack) {
            content()
                .navigationDestination(for: PushableTemplate.self) { route in
                    pushDestination(route)
                }
        }
        .sheet(
            isPresented: navigator.isModal(),
            content: {
                if let portal = navigator.presentable {
                    presentDestination(portal)
                }
            })
        .fullScreenCover(
            isPresented: navigator.isFullScreenCover(),
            content: {
                if let portal = navigator.presentable {
                    presentDestination(portal)
                }
            }
        )
        .environmentObject(navigator)
    }
}

// MARK: - Example
class ViewModel: Navigator<ViewModel.Pushed, ViewModel.Presented> {

    override var fullScreenPresentables: [Presented] {
        [.condition]
    }

    override var modalPresentables: [Presented] {
        [.legal]
    }

    enum Pushed: String, CaseIterable, Pushable {
        var id: Pushed { self }

        case home
        case register
        case forgetPassword
    }

    enum Presented: String, CaseIterable, Presentable {
        var id: Presented { self }

        case legal
        case condition
    }
}

public struct TestView: View {
    public init() {}

    @StateObject
    var viewModel: ViewModel = ViewModel()

    public var body: some View {
        NavigationControllerView(
            navigator: viewModel,
            content: {
                VStack {
                    List(ViewModel.Pushed.allCases, id: \.self) { route in
                        Button(route.rawValue) {
                            viewModel.push(to: route)
                        }
                    }

                    Button("Home") {
                        viewModel.push(to: .home)
                    }

                    Button("Term") {
                        viewModel.present(.legal)
                    }

                    Button("Condition") {
                        viewModel.present(.condition)
                    }
                }
                .navigationTitle("Login")
            },
            pushDestination: { route in
                switch route {
                case .home:
                    HomeView()
                case .register:
                    RegisterView()
                case .forgetPassword:
                    ForgotPasswordView()
                }
            },
            presentDestination: { portal in
                switch portal {
                case .legal:
                    LegalView()
                case .condition:
                    ConditionView()
                }
            }
        )
    }
}

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}

struct RegisterView: View {
    var body: some View {
        ZStack {
            Color.red
        }
    }
}

struct ForgotPasswordView: View {
    var body: some View {
        ZStack {
            Color.blue
        }
    }
}

struct LegalView: View {
    var body: some View {
        ZStack {
            Color.gray
        }
    }
}

struct ConditionView: View {
    var body: some View {
        ZStack {
            Color.orange
        }
    }
}
