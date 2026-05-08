//
//  RealtimeAudioStreamingService.swift
//  SiteClaw
//

import AVFoundation
import Foundation

enum RealtimeAudioStreamingEvent: Equatable {
    case microphonePermissionGranted
    case webSocketConnected
    case sessionConfigured
    case microphoneStarted(sampleRate: Double, channels: Int)
    case audioLevel(Double)
    case audioChunkSent(bytes: Int, totalBytes: Int)
    case speechStarted
    case speechStopped
    case inputCommitted
    case inputTranscriptDelta(String)
    case inputTranscriptCompleted(String)
    case assistantTranscriptDelta(String)
    case assistantTranscriptCompleted(String)
    case responseCompleted
    case disconnected
    case warning(String)
    case error(String)
}

enum RealtimeAudioStreamingError: LocalizedError {
    case missingClientSecret
    case invalidWebSocketURL
    case microphonePermissionDenied
    case unavailableInputFormat
    case audioConversionFailed
    case websocketUnavailable
    case realtimeServerError(String)

    var errorDescription: String? {
        switch self {
        case .missingClientSecret:
            "The Realtime session did not include a usable client secret."
        case .invalidWebSocketURL:
            "SiteClaw could not build the OpenAI Realtime WebSocket URL."
        case .microphonePermissionDenied:
            "Microphone access is required to stream owner voice onboarding."
        case .unavailableInputFormat:
            "No usable microphone input format was available."
        case .audioConversionFailed:
            "SiteClaw could not convert microphone audio to 24 kHz PCM16."
        case .websocketUnavailable:
            "The Realtime WebSocket was not available."
        case .realtimeServerError(let message):
            message
        }
    }
}

final class RealtimeAudioStreamingService {
    private let audioEngine = AVAudioEngine()
    private let urlSession: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var isRunning = false
    private var isStopping = false
    private var streamedByteCount = 0
    private var streamedChunkCount = 0
    private var pendingAudioChunks: [Data] = []
    private var isSendingAudio = false

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func start(
        session response: RealtimeSessionResponse,
        restaurantName: String,
        onEvent: @escaping (RealtimeAudioStreamingEvent) -> Void
    ) async throws {
        guard let clientSecret = response.clientSecret, !clientSecret.isEmpty else {
            throw RealtimeAudioStreamingError.missingClientSecret
        }

        guard await requestMicrophoneAccess() else {
            throw RealtimeAudioStreamingError.microphonePermissionDenied
        }

        onEvent(.microphonePermissionGranted)
        try configurePlatformAudioSession()

        let task = try makeWebSocketTask(clientSecret: clientSecret, model: response.model)
        webSocketTask = task
        isRunning = true
        isStopping = false
        streamedByteCount = 0
        streamedChunkCount = 0
        pendingAudioChunks = []
        isSendingAudio = false

        task.resume()
        onEvent(.webSocketConnected)

        try await sendSessionUpdate(
            restaurantName: restaurantName,
            transcriptionModel: response.transcriptionModel
        )
        try startAudioEngine(onEvent: onEvent)

        do {
            try await receiveEvents(onEvent: onEvent)
        } catch {
            teardownAudio()

            if isStopping || Task.isCancelled {
                onEvent(.disconnected)
                return
            }

            throw error
        }
    }

    func stop() {
        isStopping = true
        isRunning = false
        pendingAudioChunks.removeAll()
        isSendingAudio = false
        teardownAudio()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    private func makeWebSocketTask(clientSecret: String, model: String?) throws -> URLSessionWebSocketTask {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "api.openai.com"
        components.path = "/v1/realtime"
        components.queryItems = [
            URLQueryItem(name: "model", value: model?.isEmpty == false ? model : "gpt-realtime")
        ]

        guard let url = components.url else {
            throw RealtimeAudioStreamingError.invalidWebSocketURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        return urlSession.webSocketTask(with: request)
    }

    private func sendSessionUpdate(restaurantName: String, transcriptionModel: String?) async throws {
        let resolvedTranscriptionModel = transcriptionModel?.isEmpty == false
            ? transcriptionModel!
            : "gpt-realtime-whisper"

        try await sendJSONObject([
            "type": "session.update",
            "session": [
                "type": "realtime",
                "instructions": [
                    "You are SiteClaw, a friendly voice onboarding assistant for local restaurant owners.",
                    "You are helping create a website draft for \(restaurantName.isEmpty ? "the restaurant" : restaurantName).",
                    "Ask one short question at a time, listen for restaurant details, and summarize useful website copy.",
                    "Capture the restaurant name, cuisine, neighborhood, hours, menu highlights with prices, owner story, phone number if provided, and local SEO phrases.",
                ].joined(separator: " "),
                "audio": [
                    "input": [
                        "format": [
                            "type": "audio/pcm",
                            "rate": 24000,
                        ],
                        "noise_reduction": [
                            "type": "near_field",
                        ],
                        "transcription": [
                            "model": resolvedTranscriptionModel,
                            "language": "en",
                        ],
                        "turn_detection": [
                            "type": "server_vad",
                            "threshold": 0.5,
                            "prefix_padding_ms": 300,
                            "silence_duration_ms": 700,
                            "create_response": true,
                            "interrupt_response": true,
                        ],
                    ],
                ],
            ],
        ])
    }

    private func startAudioEngine(onEvent: @escaping (RealtimeAudioStreamingEvent) -> Void) throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.channelCount > 0 else {
            throw RealtimeAudioStreamingError.unavailableInputFormat
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            do {
                let pcmData = try Self.makePCM16Data(from: buffer)
                let audioLevel = Self.audioLevel(from: buffer)

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.recordAudioLevel(audioLevel, onEvent: onEvent)
                    self.enqueueAudioChunk(pcmData, onEvent: onEvent)
                }
            } catch {
                Task { @MainActor in
                    onEvent(.warning("Audio conversion failed: \(error.localizedDescription)"))
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        onEvent(.microphoneStarted(sampleRate: inputFormat.sampleRate, channels: Int(inputFormat.channelCount)))
    }

    private func teardownAudio() {
        audioEngine.inputNode.removeTap(onBus: 0)

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func configurePlatformAudioSession() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .defaultToSpeaker])
        try session.setPreferredSampleRate(24000)
        try session.setActive(true)
        #endif
    }

    private func receiveEvents(onEvent: (RealtimeAudioStreamingEvent) -> Void) async throws {
        while !Task.isCancelled {
            guard let webSocketTask else {
                throw RealtimeAudioStreamingError.websocketUnavailable
            }

            let message = try await webSocketTask.receive()

            switch message {
            case .string(let text):
                if let error = handleServerEvent(text, onEvent: onEvent) {
                    throw error
                }
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    if let error = handleServerEvent(text, onEvent: onEvent) {
                        throw error
                    }
                }
            @unknown default:
                continue
            }
        }
    }

    private func enqueueAudioChunk(_ data: Data, onEvent: @escaping (RealtimeAudioStreamingEvent) -> Void) {
        guard isRunning, !data.isEmpty else { return }

        pendingAudioChunks.append(data)
        guard !isSendingAudio else { return }

        isSendingAudio = true

        Task { @MainActor [weak self] in
            await self?.flushAudioQueue(onEvent: onEvent)
        }
    }

    private func flushAudioQueue(onEvent: (RealtimeAudioStreamingEvent) -> Void) async {
        while isRunning, !pendingAudioChunks.isEmpty {
            let data = pendingAudioChunks.removeFirst()
            await sendAudioChunk(data, onEvent: onEvent)
        }

        isSendingAudio = false
    }

    private func sendAudioChunk(_ data: Data, onEvent: (RealtimeAudioStreamingEvent) -> Void) async {
        guard isRunning, !data.isEmpty else { return }

        do {
            try await sendJSONObject([
                "type": "input_audio_buffer.append",
                "audio": data.base64EncodedString(),
            ])

            streamedByteCount += data.count
            streamedChunkCount += 1

            if streamedChunkCount == 1 || streamedChunkCount.isMultiple(of: 12) {
                onEvent(.audioChunkSent(bytes: data.count, totalBytes: streamedByteCount))
            }
        } catch {
            guard isRunning, !isStopping else { return }
            onEvent(.error("Realtime audio send failed: \(error.localizedDescription)"))
        }
    }

    private func sendJSONObject(_ payload: [String: Any]) async throws {
        guard let webSocketTask else {
            throw RealtimeAudioStreamingError.websocketUnavailable
        }

        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let text = String(data: data, encoding: .utf8) else {
            throw RealtimeAudioStreamingError.websocketUnavailable
        }

        try await webSocketTask.send(.string(text))
    }

    private func recordAudioLevel(
        _ level: Double,
        onEvent: (RealtimeAudioStreamingEvent) -> Void
    ) {
        onEvent(.audioLevel(level))
    }

    private func handleServerEvent(
        _ text: String,
        onEvent: (RealtimeAudioStreamingEvent) -> Void
    ) -> RealtimeAudioStreamingError? {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(RealtimeServerEvent.self, from: data)
        else {
            return nil
        }

        switch event.type {
        case "session.created", "session.updated":
            onEvent(.sessionConfigured)
        case "input_audio_buffer.speech_started":
            onEvent(.speechStarted)
        case "input_audio_buffer.speech_stopped":
            onEvent(.speechStopped)
        case "input_audio_buffer.committed":
            onEvent(.inputCommitted)
        case "conversation.item.input_audio_transcription.delta":
            onEvent(.inputTranscriptDelta(event.delta ?? ""))
        case "conversation.item.input_audio_transcription.completed":
            onEvent(.inputTranscriptCompleted(event.transcript ?? ""))
        case "response.output_audio_transcript.delta", "response.audio_transcript.delta", "response.output_text.delta":
            onEvent(.assistantTranscriptDelta(event.delta ?? ""))
        case "response.output_audio_transcript.done", "response.audio_transcript.done":
            onEvent(.assistantTranscriptCompleted(event.transcript ?? ""))
        case "response.output_text.done":
            onEvent(.assistantTranscriptCompleted(event.text ?? ""))
        case "response.done":
            onEvent(.responseCompleted)
        case "error":
            let message = event.error?.message ?? "OpenAI Realtime returned an error."
            onEvent(.error(message))
            return .realtimeServerError(message)
        default:
            break
        }

        return nil
    }

    nonisolated private static func makePCM16Data(from buffer: AVAudioPCMBuffer) throws -> Data {
        let inputFrameCount = Int(buffer.frameLength)
        let inputChannelCount = Int(buffer.format.channelCount)
        let inputSampleRate = buffer.format.sampleRate
        let outputSampleRate = 24000.0

        guard inputFrameCount > 0, inputChannelCount > 0, inputSampleRate > 0 else {
            throw RealtimeAudioStreamingError.audioConversionFailed
        }

        let outputFrameCount = max(1, Int((Double(inputFrameCount) * outputSampleRate / inputSampleRate).rounded(.up)))
        var data = Data()
        data.reserveCapacity(outputFrameCount * MemoryLayout<Int16>.size)

        for outputFrame in 0..<outputFrameCount {
            let sourceFrame = min(
                inputFrameCount - 1,
                Int((Double(outputFrame) * inputSampleRate / outputSampleRate).rounded(.down))
            )
            let sample = try averagedSample(
                from: buffer,
                frame: sourceFrame,
                channelCount: inputChannelCount
            )
            let clampedSample = max(-1, min(1, sample))
            let scaledSample = (clampedSample * Float(Int16.max)).rounded()
            var pcmSample = Int16(scaledSample).littleEndian

            withUnsafeBytes(of: &pcmSample) { bytes in
                data.append(contentsOf: bytes)
            }
        }

        return data
    }

    nonisolated private static func averagedSample(
        from buffer: AVAudioPCMBuffer,
        frame: Int,
        channelCount: Int
    ) throws -> Float {
        switch buffer.format.commonFormat {
        case .pcmFormatFloat32:
            try averagedSample(from: buffer, frame: frame, channelCount: channelCount, as: Float.self) { sample in
                sample
            }
        case .pcmFormatFloat64:
            try averagedSample(from: buffer, frame: frame, channelCount: channelCount, as: Double.self) { sample in
                Float(sample)
            }
        case .pcmFormatInt16:
            try averagedSample(from: buffer, frame: frame, channelCount: channelCount, as: Int16.self) { sample in
                Float(sample) / Float(Int16.max)
            }
        case .pcmFormatInt32:
            try averagedSample(from: buffer, frame: frame, channelCount: channelCount, as: Int32.self) { sample in
                Float(sample) / Float(Int32.max)
            }
        default:
            throw RealtimeAudioStreamingError.audioConversionFailed
        }
    }

    nonisolated private static func averagedSample<Sample>(
        from buffer: AVAudioPCMBuffer,
        frame: Int,
        channelCount: Int,
        as sampleType: Sample.Type,
        convert: (Sample) -> Float
    ) throws -> Float {
        let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        guard !audioBuffers.isEmpty else {
            throw RealtimeAudioStreamingError.audioConversionFailed
        }

        let usableChannelCount = min(channelCount, audioBuffers.count == 1 ? channelCount : audioBuffers.count)
        guard usableChannelCount > 0 else {
            throw RealtimeAudioStreamingError.audioConversionFailed
        }

        var sum: Float = 0

        if audioBuffers.count == 1 {
            guard let rawData = audioBuffers[0].mData else {
                throw RealtimeAudioStreamingError.audioConversionFailed
            }

            let samples = rawData.assumingMemoryBound(to: sampleType)
            let frameOffset = frame * channelCount

            for channel in 0..<usableChannelCount {
                sum += convert(samples[frameOffset + channel])
            }
        } else {
            for channel in 0..<usableChannelCount {
                guard let rawData = audioBuffers[channel].mData else {
                    throw RealtimeAudioStreamingError.audioConversionFailed
                }

                let samples = rawData.assumingMemoryBound(to: sampleType)
                sum += convert(samples[frame])
            }
        }

        return sum / Float(usableChannelCount)
    }

    nonisolated private static func audioLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0
        }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameLength > 0, channelCount > 0 else {
            return 0
        }

        var sum: Float = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]

            for frame in 0..<frameLength {
                let sample = samples[frame]
                sum += sample * sample
            }
        }

        let meanSquare = sum / Float(frameLength * channelCount)
        let rms = sqrt(meanSquare)
        return min(max(Double(rms) * 8, 0), 1)
    }
}

private struct RealtimeServerEvent: Decodable {
    var type: String
    var delta: String?
    var transcript: String?
    var text: String?
    var error: RealtimeServerError?
}

private struct RealtimeServerError: Decodable {
    var message: String?
}
