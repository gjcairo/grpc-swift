import GRPCCore
import GRPCNIOTransportHTTP2

extension RouteGuide {
  func runClient() async throws {
    let client = try GRPCClient(
      transport: .http2NIOPosix(
        target: .ipv4(host: "127.0.0.1", port: 31415),
        transportSecurity: .plaintext
      )
    )

    async let _ = client.run()

    let routeGuide = Routeguide_RouteGuide.Client(wrapping: client)
    try await self.getFeature(using: routeGuide)
  }

  private func getFeature(using routeGuide: Routeguide_RouteGuide.Client) async throws {
    print("→ Calling 'GetFeature'")

    let point = Routeguide_Point.with {
      $0.latitude = 407_838_351
      $0.longitude = -746_143_763
    }

    let feature = try await routeGuide.getFeature(point)
    print("Got feature '\(feature.name)'")
  }
}
