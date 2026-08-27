import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

struct IconRendererCodexGrokBotBrandIconTests {
    @MainActor
    @Test
    func `stack draws brand marks beside both meter lanes`() throws {
        let image = try IconRenderer.makeIcon(
            primaryRemaining: 0,
            weeklyRemaining: 0,
            creditsRemaining: nil,
            stale: false,
            style: .codex,
            lanePresentation: .codexGrokBot,
            laneBrandIcons: IconRenderer.LaneBrandIcons(
                top: #require(ProviderBrandIcon.image(for: .codex)),
                bottom: #require(ProviderBrandIcon.image(for: .grok))),
            quotaLayoutPolicy: .provider(.codex))
        let rep = try #require(image.representations.compactMap { $0 as? NSBitmapImageRep }.first { rep in
            rep.pixelsWide == 36 && rep.pixelsHigh == 36
        })

        func alphaSum(x: ClosedRange<Int>, y: ClosedRange<Int>) -> CGFloat {
            x.reduce(0) { xTotal, xValue in
                xTotal + y.reduce(0) { yTotal, yValue in
                    yTotal + (rep.colorAt(x: xValue, y: yValue) ?? .clear).alphaComponent
                }
            }
        }

        #expect(alphaSum(x: 0...9, y: 20...29) > 1)
        #expect(alphaSum(x: 0...9, y: 6...15) > 1)
        #expect(alphaSum(x: 10...11, y: 6...29) < 0.1)
        #expect(alphaSum(x: 12...35, y: 20...29) > 1)
        #expect(alphaSum(x: 12...35, y: 6...15) > 1)
    }
}
