import CryptoKit
import Foundation
import Testing
@testable import SafeKeep

struct CryptoServiceTests {
    @Test func sealAndOpenRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let message = Data("correct horse battery staple".utf8)
        let sealed = try CryptoService.seal(message, using: key, context: "test")
        #expect(sealed != message)
        #expect(try CryptoService.open(sealed, using: key, context: "test") == message)
    }

    @Test func tamperedCiphertextIsRejected() throws {
        let key = SymmetricKey(size: .bits256)
        var sealed = try CryptoService.seal(Data("secret".utf8), using: key, context: "test")
        sealed[sealed.count / 2] ^= 0x01
        #expect(throws: CryptoError.openFailed) {
            try CryptoService.open(sealed, using: key, context: "test")
        }
    }

    @Test func wrongKeyIsRejected() throws {
        let sealed = try CryptoService.seal(Data("secret".utf8), using: SymmetricKey(size: .bits256), context: "test")
        #expect(throws: CryptoError.openFailed) {
            try CryptoService.open(sealed, using: SymmetricKey(size: .bits256), context: "test")
        }
    }

    @Test func contextIsBoundToCiphertext() throws {
        let key = SymmetricKey(size: .bits256)
        let sealed = try CryptoService.seal(Data("secret".utf8), using: key, context: "vault")
        #expect(throws: CryptoError.openFailed) {
            try CryptoService.open(sealed, using: key, context: "backup")
        }
    }

    @Test func keyDerivationIsDeterministicPerSalt() throws {
        let salt = try CryptoService.randomBytes(count: 16)
        let first = try CryptoService.deriveKey(from: "482913", salt: salt, iterations: TestSupport.fastIterations)
        let second = try CryptoService.deriveKey(from: "482913", salt: salt, iterations: TestSupport.fastIterations)
        let otherSalt = try CryptoService.deriveKey(
            from: "482913", salt: CryptoService.randomBytes(count: 16), iterations: TestSupport.fastIterations
        )
        #expect(first.rawData == second.rawData)
        #expect(first.rawData != otherSalt.rawData)
    }

    @Test func calibrationRespectsMinimum() {
        #expect(CryptoService.calibratedIterations(targetMilliseconds: 1) >= CryptoService.minimumIterations)
    }

    @Test func randomBytesAreUnique() throws {
        #expect(try CryptoService.randomBytes(count: 32) != CryptoService.randomBytes(count: 32))
    }
}
