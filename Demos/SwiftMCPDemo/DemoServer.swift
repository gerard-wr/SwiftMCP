import Foundation
import SwiftMCP

/**
 A Calculator for simple math doing additionals, subtractions etc.
 
 Testing "quoted" stuff. And on multiple lines. 'single quotes'
 */
@MCPServer(name: "SwiftMCP Demo")
actor DemoServer {
	
    // MARK: - Tools

	/**
	 Obfuscates a string using ROT13 encoding

	 ROT13 is a simple letter substitution cipher that replaces a letter with
	 the letter 13 positions after it in the alphabet. Non-alphabetic characters
	 are left unchanged.

	 - Parameter text: The string to obfuscate
	 - Returns: The obfuscated string
	 */
	@MCPTool(description: "Obfuscates a string using ROT13 encoding")
	func obfuscate(text: String) async -> String {
		await Session.current?.sendLogNotification(LogMessage(level: .info, data: [
			"function": "obfuscate",
			"message": "obfuscate called",
			"arguments": ["text": text]
		]))

		return text.map { char in
			switch char {
			case "A"..."M", "a"..."m":
				return Character(UnicodeScalar(char.asciiValue! + 13))
			case "N"..."Z", "n"..."z":
				return Character(UnicodeScalar(char.asciiValue! - 13))
			default:
				return char
			}
		}.reduce("") { $0 + String($1) }
	}

	/**
	 Decodes a ROT13 obfuscated string back to its original form

	 Since ROT13 is its own inverse, this function applies the same
	 transformation as obfuscate to decode the text.

	 - Parameter text: The obfuscated string to decode
	 - Returns: The decoded string
	 */
	@MCPTool(description: "Decodes a ROT13 obfuscated string")
	func decode(text: String) async -> String {
		await Session.current?.sendLogNotification(LogMessage(level: .info, data: [
			"function": "decode",
			"message": "decode called",
			"arguments": ["text": text]
		]))

		// ROT13 is its own inverse, so decoding is the same as encoding
		return text.map { char in
			switch char {
			case "A"..."M", "a"..."m":
				return Character(UnicodeScalar(char.asciiValue! + 13))
			case "N"..."Z", "n"..."z":
				return Character(UnicodeScalar(char.asciiValue! - 13))
			default:
				return char
			}
		}.reduce("") { $0 + String($1) }
	}

    // MARK: - Notifications
    
    /**
     Handles the roots list changed notification from the client.
     
     This implementation retrieves the updated list of roots from the client session
     whenever a 'roots/list_changed' notification is received. It then logs the new
     list of roots (including their URIs and names) for debugging and verification.
     If an error occurs while retrieving the roots, it logs a warning with the error message.
     */
    func handleRootsListChanged() async {
        guard let session = Session.current else { return }
        do {
            let updatedRoots = try await session.listRoots()
            await session.sendLogNotification(LogMessage(
                level: .info,
                data: [
                    "message": "Roots list updated",
                    "roots": updatedRoots
                ]
            ))
        } catch {
            await session.sendLogNotification(LogMessage(
                level: .warning,
                data: [
                    "message": "Failed to retrieve updated roots list",
                    "error": error.localizedDescription
                ]
            ))
        }
    }
}

