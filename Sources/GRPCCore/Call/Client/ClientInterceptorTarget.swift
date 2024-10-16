/*
 * Copyright 2024, gRPC Authors All rights reserved.
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

public struct ClientInterceptorTarget: Sendable {
  internal enum Wrapped: Sendable {
    case allServices(interceptor: any ClientInterceptor)
    case serviceSpecific(interceptor: any ClientInterceptor, services: [String])
    case methodSpecific(interceptor: any ClientInterceptor, methods: [MethodDescriptor])
  }

  public static func allServices(
    interceptor: any ClientInterceptor
  ) -> Self {
    Self(wrapped: .allServices(interceptor: interceptor))
  }

  public static func serviceSpecific(
    interceptor: any ClientInterceptor,
    services: [String]
  ) -> Self {
    Self(
      wrapped: .serviceSpecific(
        interceptor: interceptor,
        services: services
      )
    )
  }

  public static func methodSpecific(
    interceptor: any ClientInterceptor,
    methods: [MethodDescriptor]
  ) -> Self {
    Self(
      wrapped: .methodSpecific(
        interceptor: interceptor,
        methods: methods
      )
    )
  }

  private let wrapped: Wrapped

  private init(wrapped: Wrapped) {
    self.wrapped = wrapped
  }

  public var interceptor: any ClientInterceptor {
    switch self.wrapped {
    case .allServices(let interceptor):
      return interceptor
    case .serviceSpecific(let interceptor, _):
      return interceptor
    case .methodSpecific(let interceptor, _):
      return interceptor
    }
  }

  public func applies(to descriptor: MethodDescriptor) -> Bool {
    switch self.wrapped {
    case .allServices:
      return true
    case .serviceSpecific(_, let services):
      return services.contains(descriptor.service)
    case .methodSpecific(_, let methods):
      return methods.contains(descriptor)
    }
  }
}
