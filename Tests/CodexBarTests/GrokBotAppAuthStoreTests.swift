import Foundation
import Testing
@testable import CodexBarCore

#if os(macOS)
@Suite(.serialized)
struct GrokBotAppAuthStoreTests {
    private static let accessToken =
        "eyJhbGciOiJub25lIn0." +
        "eyJzdWIiOiJhdXRoMHxib3QtdXNlciIsImVtYWlsIjoiYm90QGV4YW1wbGUuY29tIiwiZXhwIjo0MTAyNDQ0ODAwfQ.sig"
    private static let encryptedAccessToken =
        "djEwWYhmSnp1q+qiTrBMIfHTGiaocfNxVB1uHnqJLpROHUsnz+dm5VzCtVLNxuiDqK1mt752aN2knyD93fmJXv/" +
        "SzMm3cdkiG0mVOI8hjJDSNstfIFmvkF6BIZUAnapsJgrWU0gSAx+2B4EldFNrz7kqIKvvOq0J1qZCO4rDCQfZ644="

    @Test
    func `decrypts the active Grok Bot Cursor account`() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("codexbar-grok-bot-auth-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let accounts: [String: Any] = [
            "active": "active-account",
            "accounts": [
                "active-account": ["cursor-access-token": Self.encryptedAccessToken],
            ],
        ]
        let accountsData = try JSONSerialization.data(withJSONObject: accounts)
        let accountsString = try #require(String(data: accountsData, encoding: .utf8))
        let secretsData = try JSONSerialization.data(withJSONObject: ["cursor-accounts": accountsString])
        let secretsURL = directory.appendingPathComponent("sand-secrets.json")
        try secretsData.write(to: secretsURL)

        let store = GrokBotAppAuthStore(
            secretsPath: secretsURL.path,
            passwordProvider: { "test-password" })
        let loadedSession = try store.loadSession()
        let session = try #require(loadedSession)

        #expect(session.accessToken == Self.accessToken)
        #expect(session.source == .grokBotApp)
        #expect(session.identity?.displayLabel == "bot@example.com")
        #expect(session.isUsable)
    }

    @Test
    func `desktop auth prefers a usable Grok Bot session`() throws {
        let grokSession = CursorAppAuthSession(accessToken: Self.accessToken, source: .grokBotApp)
        let cursorSession = CursorAppAuthSession(accessToken: Self.accessToken, source: .cursorApp)
        let store = CursorDesktopAuthStore(
            grokBotStore: CursorDesktopAuthSessionStub(session: grokSession),
            cursorAppStore: CursorDesktopAuthSessionStub(session: cursorSession))

        #expect(try store.loadSession()?.source == .grokBotApp)
    }

    @Test
    func `desktop auth falls back to Cursor app when Grok Bot is unavailable`() throws {
        let cursorSession = CursorAppAuthSession(accessToken: Self.accessToken, source: .cursorApp)
        let store = CursorDesktopAuthStore(
            grokBotStore: CursorDesktopAuthSessionStub(session: nil),
            cursorAppStore: CursorDesktopAuthSessionStub(session: cursorSession))

        #expect(try store.loadSession()?.source == .cursorApp)
    }

    @Test
    func `default secrets path follows the supplied home`() {
        #expect(GrokBotAppAuthStore.resolveDefaultSecretsPath(home: "/tmp/home") ==
            "/tmp/home/Library/Application Support/Grok Bot/sand-secrets.json")
    }
}

private struct CursorDesktopAuthSessionStub: CursorAppAuthSessionProviding {
    let session: CursorAppAuthSession?

    func loadSession() throws -> CursorAppAuthSession? {
        self.session
    }
}
#endif
