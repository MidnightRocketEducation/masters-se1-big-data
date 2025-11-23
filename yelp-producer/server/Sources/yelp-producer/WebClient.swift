import Foundation;
#if canImport(FoundationNetworking)
import FoundationNetworking;
#endif


struct WebClient {
	static private let session = URLSession.shared;

	static func run(url: URL, method: Method, body: Data? = nil, accept: AcceptType = .json, token: String? = nil) async -> Data? {
		var request = URLRequest(url: url);
		request.httpMethod = method.rawValue;
		if let token = token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization");
		}
		request.setValue(accept.rawValue, forHTTPHeaderField: "accept");
		request.httpBody = body;
		do {
			let (data, _) = try await Self.session.data(for: request)
			return data;
		} catch(let e) {
			stderr(e);
			return nil;
		}
	}

	@discardableResult
	static func post(url: URL, body: Data? = nil, accept: AcceptType = .json, token: String? = nil) async -> Data? {
		return await Self.run(url: url, method: .post, body: body, accept: accept, token: token);
	}
}


extension WebClient {
	enum Method: String {
		case get = "GET";
		case post = "POST";
		case put = "PUT";
		case delete = "DELETE";
	}

	enum AcceptType: String {
		case json = "application/json";
	}
}
