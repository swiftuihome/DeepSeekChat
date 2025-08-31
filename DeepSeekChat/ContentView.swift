//
//  ContentView.swift
//  DeepSeekChat
//
//  Created by devlink on 2025/8/31.
//

import SwiftUI
import MarkdownUI

struct ContentView: View {
    @StateObject private var viewModel = DeepSeekViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("DeepSeek Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    viewModel.clearConversation()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .disabled(viewModel.isStreaming)
            }
            .padding()
            .background(Color(.systemBackground).shadow(radius: 1))
            
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            if case .system = message {
                                // 不显示系统消息
                            } else {
                                MessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        
                        // 显示正在输入的流式消息
                        if viewModel.isStreaming && !viewModel.streamingResponse.isEmpty {
                            MessageView(message: .assistant(content: viewModel.streamingResponse))
                                .id("streaming")
                                .opacity(0.9)
                        }
                        
                        // 显示使用情况
                        if let usage = viewModel.usage, viewModel.showUsage {
                            UsageView(usage: usage)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.streamingResponse) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // 输入区域
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // 文本输入框
                    TextField("输入消息...", text: $inputText, axis: .vertical)
                        .focused($isInputFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(13)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    // 发送按钮
                    Button(action: sendMessage) {
                        if viewModel.isStreaming {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .frame(width: 20, height: 20)
                        }
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            // 添加用户消息
            await MainActor.run {
                viewModel.addMessage(.user(content: trimmedText))
                inputText = ""
                isInputFocused = false
            }
            
            // 发送流式消息
            await viewModel.sendStreamingMessage()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if viewModel.isStreaming && !viewModel.streamingResponse.isEmpty {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// 消息视图
struct MessageView: View {
    let message: DeepSeekChatCompletionRequestBody.Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 用户消息向右对齐
            if case .user = message {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: hAlignment, spacing: 6) {
                // 角色标签
                HStack {
                    if case .assistant = message {
                        roleIcon
                        roleText
                    }
                    
                    Spacer()
                    
                    if case .user = message {
                        roleText
                        roleIcon
                    }
                }
                
                // Markdown 内容
                MarkdownContent(message: message)
                    .padding(14)
                    .background(backgroundColor)
                    .cornerRadius(13)
            }
            .frame(alignment: alignment)
            
            // 助手消息向左对齐
            if case .assistant = message {
                Spacer(minLength: 40)
            }
        }
    }
    
    private var alignment: Alignment {
        switch message {
        case .user: return .trailing
        case .assistant: return .leading
        case .system: return .leading
        case .tool: return .leading
        }
    }
    
    private var hAlignment: HorizontalAlignment {
        switch message {
        case .user: return .trailing
        case .assistant: return .leading
        case .system: return .leading
        case .tool: return .leading
        }
    }
    
    private var roleText: some View {
        Text(roleString)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
    }
    
    private var roleIcon: some View {
        Image(systemName: iconName)
            .font(.caption)
            .foregroundColor(iconColor)
    }
    
    private var roleString: String {
        switch message {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        case .tool: return "Tool"
        }
    }
    
    private var iconName: String {
        switch message {
        case .user: return "person.circle.fill"
        case .assistant: return "brain.head.profile"
        case .system: return "gear.circle.fill"
        case .tool: return "wrench.fill"
        }
    }
    
    private var iconColor: Color {
        switch message {
        case .user: return .blue
        case .assistant: return .green
        case .system: return .gray
        case .tool: return .orange
        }
    }
    
    private var backgroundColor: Color {
        switch message {
        case .user: return Color.blue.opacity(0.15)
        case .assistant: return Color.purple.opacity(0.15)
        case .system: return Color.gray.opacity(0.15)
        case .tool: return Color.orange.opacity(0.15)
        }
    }
}

// Markdown 内容视图
struct MarkdownContent: View {
    let message: DeepSeekChatCompletionRequestBody.Message
    
    var body: some View {
        Group {
            switch message {
            case .user(let content, _):
                Markdown(content)
                    .markdownTheme(.docC)
                
            case .assistant(let content, _, _, _):
                Markdown(content)
                    .markdownTheme(.docC)
                
            case .system(let content, _):
                Markdown(content)
                    .markdownTheme(.docC)
                
            case .tool(let content, _):
                Markdown(content)
                    .markdownTheme(.docC)
            }
        }
    }
}

// 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// 发送按钮样式
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// 使用情况视图
struct UsageView: View {
    let usage: DeepSeekUsage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Token Usage")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                if let promptTokens = usage.promptTokens {
                    usageRow("Prompt Tokens", value: "\(promptTokens)")
                }
                if let completionTokens = usage.completionTokens {
                    usageRow("Completion Tokens", value: "\(completionTokens)")
                }
                if let totalTokens = usage.totalTokens {
                    usageRow("Total Tokens", value: "\(totalTokens)", isTotal: true)
                }
                if let reasoningTokens = usage.completionTokensDetails?.reasoningTokens {
                    usageRow("Reasoning Tokens", value: "\(reasoningTokens)")
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func usageRow(_ title: String, value: String, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(isTotal ? .bold : .regular)
                .foregroundColor(isTotal ? .blue : .primary)
        }
    }
}

#Preview {
    ContentView()
}
