import UIKit

struct Cards: Decodable {
    var cards: [Card]
}

struct Card: Decodable {
    var name: String?
    var type: String?
    var rarity: String?
    var manaCost: String?
    var setName: String?
}

enum NetworkError: Error {
    case networkProblem
    case serverFail
    case invalidRequest((Int, String))
}

extension NetworkError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .networkProblem: return ""
        case .serverFail: return ""
        case .invalidRequest((_, let message)): return message
        }
    }

}

typealias EndpointCompletion = (Result<Cards, NetworkError>) -> Void

func makeURL(with cardName: String) -> URL? {
    var urlComponents: URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.magicthegathering.io"
        urlComponents.path = "/v1/cards"
        urlComponents.queryItems = [
            URLQueryItem(name: "name", value: cardName)
        ]
        return urlComponents
    }
    return urlComponents.url
}

func getData(cardName: String, completion: @escaping EndpointCompletion) {
    guard let url = makeURL(with: cardName) else { return }

    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let response = response as? HTTPURLResponse else {
            completion(Result.failure(.networkProblem))
            return
        }
        print("Код ответа от сервера: \(response.statusCode)\n")

        switch response.statusCode {
        case 200:
            guard let data = data else { return }
            do {
                let returnData = try JSONDecoder().decode(Cards.self, from: data)
                completion(Result.success(returnData))
            } catch let error as NSError {
                print("\(error), \(error.userInfo)")
            }
        case 500:
            completion(Result.failure(.serverFail))
        default:
            if let error = error as NSError? {
                let errorTuple = (error.code, error.localizedDescription)
                completion(Result.failure(.invalidRequest(errorTuple)))
            }
        }
    }.resume()
}

let blackLotus = "Black Lotus"
let opt = "Opt"

getData(cardName: opt) { result in
    switch result {
    case .success(let data):
        data.cards.forEach {
            print(
                """
                Имя карты: \($0.name ?? "")
                Тип: \($0.type ?? "")
                Редкость: \($0.rarity ?? "")
                Мановая стоимость: \($0.manaCost ?? "")
                Название сета: \($0.setName ?? "")\n
                """
            )
        }
    case .failure(let error):
        print(error)
    }
}
