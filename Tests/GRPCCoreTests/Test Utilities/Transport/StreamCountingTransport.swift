/*
 * Copyright 2023, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Atomics

@testable import GRPCCore

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
struct StreamCountingClientTransport: ClientTransport, Sendable {
  typealias Inbound = RPCAsyncSequence<RPCResponsePart, any Error>
  typealias Outbound = RPCWriter<RPCRequestPart>.Closable

  private let transport: AnyClientTransport
  private let _streamsOpened = ManagedAtomic(0)
  private let _streamFailures = ManagedAtomic(0)

  var streamsOpened: Int {
    self._streamsOpened.load(ordering: .sequentiallyConsistent)
  }

  var streamFailures: Int {
    self._streamFailures.load(ordering: .sequentiallyConsistent)
  }

  init<Transport: ClientTransport>(wrapping transport: Transport)
  where Transport.Inbound == Inbound, Transport.Outbound == Outbound {
    self.transport = AnyClientTransport(wrapping: transport)
  }

  var retryThrottle: RetryThrottle? {
    self.transport.retryThrottle
  }

  func connect() async throws {
    try await self.transport.connect()
  }

  func close() {
    self.transport.close()
  }

  func withStream<T>(
    descriptor: MethodDescriptor,
    options: CallOptions,
    _ closure: (RPCStream<Inbound, Outbound>) async throws -> T
  ) async throws -> T {
    do {
      return try await self.transport.withStream(
        descriptor: descriptor,
        options: options
      ) { stream in
        self._streamsOpened.wrappingIncrement(ordering: .sequentiallyConsistent)
        return try await closure(stream)
      }
    } catch {
      self._streamFailures.wrappingIncrement(ordering: .sequentiallyConsistent)
      throw error
    }
  }

  func configuration(
    forMethod descriptor: MethodDescriptor
  ) -> MethodConfig? {
    self.transport.configuration(forMethod: descriptor)
  }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
struct StreamCountingServerTransport: ServerTransport, Sendable {
  typealias Inbound = RPCAsyncSequence<RPCRequestPart, any Error>
  typealias Outbound = RPCWriter<RPCResponsePart>.Closable

  private let transport: AnyServerTransport
  private let _acceptedStreams = ManagedAtomic(0)

  var acceptedStreamsCount: Int {
    self._acceptedStreams.load(ordering: .sequentiallyConsistent)
  }

  init<Transport: ServerTransport>(wrapping transport: Transport) {
    self.transport = AnyServerTransport(wrapping: transport)
  }

  func listen(
    _ streamHandler: @escaping @Sendable (RPCStream<Inbound, Outbound>) async -> Void
  ) async throws {
    try await self.transport.listen { stream in
      self._acceptedStreams.wrappingIncrement(ordering: .sequentiallyConsistent)
      await streamHandler(stream)
    }
  }

  func stopListening() {
    self.transport.stopListening()
  }
}
