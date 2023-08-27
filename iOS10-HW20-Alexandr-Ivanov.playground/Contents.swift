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

func getData(cardName: String, completion: @escaping EndpointCompletion) {
    let url = "https://api.magicthegathering.io/v1/cards?name=\(cardName)"
    let urlRequest = URL(string: url)
    guard let url = urlRequest else { return }

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

let blackLotus = "Black%20Lotus"
let opt = "Opt"

getData(cardName: blackLotus) { result in
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
