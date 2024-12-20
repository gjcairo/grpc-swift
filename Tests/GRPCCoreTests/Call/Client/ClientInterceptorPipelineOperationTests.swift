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

import Testing

@testable import GRPCCore

@Suite("ClientInterceptorPipelineOperation")
struct ClientInterceptorPipelineOperationTests {
  @Test(
    "Applies to",
    arguments: [
      (
        .all,
        [.fooBar, .fooBaz, .barFoo, .barBaz],
        []
      ),
      (
        .services([ServiceDescriptor(package: "pkg", service: "foo")]),
        [.fooBar, .fooBaz],
        [.barFoo, .barBaz]
      ),
      (
        .methods([.barFoo]),
        [.barFoo],
        [.fooBar, .fooBaz, .barBaz]
      ),
    ] as [(ClientInterceptorPipelineOperation.Subject, [MethodDescriptor], [MethodDescriptor])]
  )
  func appliesTo(
    operationSubject: ClientInterceptorPipelineOperation.Subject,
    applicableMethods: [MethodDescriptor],
    notApplicableMethods: [MethodDescriptor]
  ) {
    let operation = ClientInterceptorPipelineOperation.apply(
      .requestCounter(.init()),
      to: operationSubject
    )

    for applicableMethod in applicableMethods {
      #expect(operation.applies(to: applicableMethod))
    }

    for notApplicableMethod in notApplicableMethods {
      #expect(!operation.applies(to: notApplicableMethod))
    }
  }
}

extension MethodDescriptor {
  fileprivate static let fooBar = Self(fullyQualifiedService: "pkg.foo", method: "bar")
  fileprivate static let fooBaz = Self(fullyQualifiedService: "pkg.foo", method: "baz")
  fileprivate static let barFoo = Self(fullyQualifiedService: "pkg.bar", method: "foo")
  fileprivate static let barBaz = Self(fullyQualifiedService: "pkg.bar", method: "Baz")
}
