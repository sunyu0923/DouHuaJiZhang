import SwiftUI
import ComposableArchitecture

/// 认证入口视图 — 根据 mode 切换欢迎页/登录页/注册页
struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>
    
    var body: some View {
        NavigationStack {
            Group {
                switch store.mode {
                case .welcome:
                    WelcomeView(store: store)
                case .login:
                    LoginView(store: store)
                case .register:
                    RegisterView(store: store)
                }
            }
            .pageBackground()
        }
    }
}

// MARK: - 欢迎页

struct WelcomeView: View {
    let store: StoreOf<AuthFeature>
    
    var body: some View {
        ZStack {
            Image("LoginHero")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 14) {
                    AuthLandingButton(
                        title: "手机号登录",
                        icon: "iphone",
                        style: .phone
                    ) {
                        store.send(.setMode(.login))
                    }

                    AuthLandingButton(
                        title: "微信登录",
                        icon: "WeChatIcon",
                        style: .wechat
                    ) {
                        store.send(.loginWithWechat)
                    }

                    AuthLandingButton(
                        title: "注册",
                        icon: nil,
                        style: .register
                    ) {
                        store.send(.setMode(.register))
                    }

                    Button {
                        store.send(.setMode(.login))
                    } label: {
                        HStack(spacing: 6) {
                            Text("忘记密码？")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 52)
            }
        }
    }
}

private struct AuthLandingButton: View {
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    enum Style {
        case phone
        case wechat
        case register
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if let icon {
                    if style == .wechat {
                        Image(icon)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                    }
                }
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 2)
                    )
            )
        }
    }

    private var background: Color {
        switch style {
        case .phone: return .white.opacity(0.96)
        case .wechat: return .white.opacity(0.02)
        case .register: return Color(hex: "6F4CD7")
        }
    }

    private var foreground: Color {
        switch style {
        case .phone: return Color(hex: "6F4CD7")
        case .wechat: return .white.opacity(0.95)
        case .register: return .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .wechat: return .white.opacity(0.75)
        default: return .clear
        }
    }
}

// MARK: - 登录页

struct LoginView: View {
    @Bindable var store: StoreOf<AuthFeature>
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 豆花形象
            DouhuaIPView(size: .medium, mood: .happy)
                .padding(.top, DesignSystem.Spacing.xxl)
            
            // 登录方式切换
            Picker("登录方式", selection: $store.loginMethod.sending(\.setLoginMethod)) {
                Text("密码登录").tag(AuthFeature.LoginMethod.password)
                Text("验证码登录").tag(AuthFeature.LoginMethod.verificationCode)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                // 手机号
                TextField("请输入手机号", text: $store.phone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                
                if store.loginMethod == .password {
                    // 密码
                    HStack {
                        if store.isPasswordVisible {
                            TextField("请输入密码", text: $store.password)
                        } else {
                            SecureField("请输入密码", text: $store.password)
                        }
                        Button {
                            store.send(.togglePasswordVisibility)
                        } label: {
                            Image(systemName: store.isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                } else {
                    // 验证码
                    HStack {
                        TextField("请输入验证码", text: $store.verificationCode)
                            .keyboardType(.numberPad)
                        
                        Button {
                            store.send(.sendVerificationCode(store.phone))
                        } label: {
                            Text(store.codeSentCountdown > 0 ? "\(store.codeSentCountdown)s" : "获取验证码")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(store.codeSentCountdown > 0 ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary)
                        }
                        .disabled(store.codeSentCountdown > 0)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                }
            }
            
            // Error message
            if let error = store.errorMessage {
                Text(error)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.expense)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
            }
            
            // 登录按钮
            RoundedButton("登录", isEnabled: store.canLogin) {
                store.send(.login)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            
            if store.isLoading {
                ProgressView()
            }
            
            // 底部链接
            HStack {
                Button("忘记密码") {
                    // TODO: Password recovery
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Button("微信快捷登录") {
                    store.send(.loginWithWechat)
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            
            Spacer()
        }
        .navigationTitle("登录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.setMode(.welcome))
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

// MARK: - 注册页

struct RegisterView: View {
    @Bindable var store: StoreOf<AuthFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // 豆花形象
                DouhuaIPView(
                    size: .medium,
                    mood: .happy,
                    showQuote: true,
                    quote: DouhuaQuoteManager.randomQuote(for: .register)
                )
                .padding(.top, DesignSystem.Spacing.xl)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    // 手机号
                    TextField("请输入手机号", text: $store.registerPhone)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    
                    // 验证码
                    HStack {
                        TextField("请输入验证码", text: $store.registerVerificationCode)
                            .keyboardType(.numberPad)
                        
                        Button {
                            store.send(.sendVerificationCode(store.registerPhone))
                        } label: {
                            Text(store.codeSentCountdown > 0 ? "\(store.codeSentCountdown)s" : "获取验证码")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(store.codeSentCountdown > 0 ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary)
                        }
                        .disabled(store.codeSentCountdown > 0)
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    // 密码
                    HStack {
                        if store.isRegisterPasswordVisible {
                            TextField("请输入密码(6-18位字母+数字)", text: $store.registerPassword)
                        } else {
                            SecureField("请输入密码(6-18位字母+数字)", text: $store.registerPassword)
                        }
                        Button {
                            store.send(.toggleRegisterPasswordVisibility)
                        } label: {
                            Image(systemName: store.isRegisterPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    // 确认密码
                    SecureField("请确认密码", text: $store.registerConfirmPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    if store.registerPassword != store.registerConfirmPassword && !store.registerConfirmPassword.isEmpty {
                        Text("两次输入的密码不一致")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.expense)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                
                // 用户协议
                HStack {
                    Button {
                        store.send(.binding(.set(\.hasAgreedToTerms, !store.hasAgreedToTerms)))
                    } label: {
                        Image(systemName: store.hasAgreedToTerms ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(store.hasAgreedToTerms ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                    }
                    
                    Text("同意")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    
                    Button("《用户协议》") {
                        // TODO: Show terms
                    }
                    .font(DesignSystem.Typography.caption)
                    
                    Text("和")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    
                    Button("《隐私政策》") {
                        // TODO: Show privacy policy
                    }
                    .font(DesignSystem.Typography.caption)
                }
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                
                // Error message
                if let error = store.errorMessage {
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.expense)
                        .padding(.horizontal, DesignSystem.Spacing.xxl)
                }
                
                // 注册按钮
                RoundedButton("注册并登录", isEnabled: store.canRegister) {
                    store.send(.register)
                }
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                
                if store.isLoading {
                    ProgressView()
                }
                
                // 已注册？去登录
                Button {
                    store.send(.setMode(.login))
                } label: {
                    Text("已注册？去登录")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                
                Spacer()
            }
        }
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.setMode(.welcome))
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}
