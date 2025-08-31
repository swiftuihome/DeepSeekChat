//
//  DeepSeekViewModel.swift
//  DeepSeekAPI
//
//  Created by devlink on 2025/8/31.
//

import SwiftUI

// 视图模型
@MainActor
class DeepSeekViewModel: ObservableObject {
    @Published var messages: [DeepSeekChatCompletionRequestBody.Message] = []
    @Published var streamingResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var usage: DeepSeekUsage?
    @Published var showUsage: Bool = true
    
    let deepSeekService: DeepSeekService
    
    init() {
        // 初始化 DeepSeek 服务 - 替换为你的实际 API 密钥
        self.deepSeekService = DeepSeekDirectService(unprotectedAPIKey: "your_api_key")
        
        // 添加系统消息
        messages.append(.system(content: "You are a helpful assistant. Respond in the same language as the user."))
    }
    
    func addMessage(_ message: DeepSeekChatCompletionRequestBody.Message) {
        messages.append(message)
    }
    
    func sendStreamingMessage() async {
        startStreamingResponse()
        
        do {
            let requestBody = DeepSeekChatCompletionRequestBody(
                messages: messages,
                model: "deepseek-chat",
                maxTokens: 1000, temperature: 0.7
            )
            
            let stream = try await deepSeekService.streamingChatCompletionRequest(body: requestBody)
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content, !content.isEmpty {
                    await MainActor.run {
                        self.streamingResponse += content
                    }
                }
                if let usage = chunk.usage {
                    await MainActor.run {
                        self.usage = usage
                    }
                }
            }
            
            await MainActor.run {
                self.finishStreamingResponse()
            }
            
        } catch {
            print("Streaming error: \(error.localizedDescription)")
            await MainActor.run {
                self.cancelStreamingResponse()
                self.addMessage(.assistant(content: "抱歉，发生了错误：\(error.localizedDescription)"))
            }
        }
    }
    
    func startStreamingResponse() {
        isStreaming = true
        streamingResponse = ""
    }
    
    func appendToStreamingResponse(_ content: String) {
        streamingResponse += content
    }
    
    func finishStreamingResponse() {
        if !streamingResponse.isEmpty {
            messages.append(.assistant(content: streamingResponse))
        }
        isStreaming = false
        streamingResponse = ""
    }
    
    func cancelStreamingResponse() {
        isStreaming = false
        streamingResponse = ""
    }
    
    func clearConversation() {
        messages.removeAll()
        streamingResponse = ""
        isStreaming = false
        usage = nil
        // 重新添加系统消息
        messages.append(.system(content: "You are a helpful assistant. Respond in the same language as the user."))
    }
}

// 让 Message 可识别
extension DeepSeekChatCompletionRequestBody.Message: Identifiable {
    public var id: String {
        switch self {
        case .user(let content, let name):
            return "user_\(content.hashValue)_\(name ?? "")"
        case .assistant(let content, let name, let prefix, let reasoningContent):
            return "assistant_\(content.hashValue)_\(name ?? "")_\(prefix?.description ?? "")_\(reasoningContent ?? "")"
        case .system(let content, let name):
            return "system_\(content.hashValue)_\(name ?? "")"
        case .tool(let content, let toolCallID):
            return "tool_\(content.hashValue)_\(toolCallID)"
        }
    }
}
