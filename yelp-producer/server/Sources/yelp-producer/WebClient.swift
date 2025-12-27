import Foundation;
#if canImport(FoundationNetworking)
import FoundationNetworking;
#endif


struct WebClient {
	static private let session = URLSession.shared;

	static func run(
		url: URL,
		method: Method = .get,
		body: Data? = nil,
		accept: MimeType = .json,
		contentType: MimeType? = nil,
		token: String? = nil
	) async throws -> Data {
		var request = URLRequest(url: url);
		request.httpMethod = method.rawValue;
		if let token = token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization");
		}
		request.setValue(accept.rawValue, forHTTPHeaderField: "accept");
		if let contentType = contentType {
			request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type");
		}
		request.httpBody = body;
		let (data, _) = try await Self.session.data(for: request)
		return data;
	}

	@discardableResult
	static func post(
		url: URL,
		body: Data? = nil,
		accept: MimeType = .json,
		contentType: MimeType? = nil,
		token: String? = nil
	) async throws -> Data {
		return try await Self.run(url: url, method: .post, body: body, accept: accept, contentType: contentType, token: token);
	}
}


extension WebClient {
	enum Method: String {
		case get = "GET";
		case post = "POST";
		case put = "PUT";
		case delete = "DELETE";
	}

	enum MimeType: String {
		case json = "application/json";
		case confluentSchema = "application/vnd.schemaregistry.v1+json";
	}
}
