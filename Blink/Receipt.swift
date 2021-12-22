//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import Combine
import CryptoKit
import Foundation
import StoreKit
import SwiftUI

import Purchases

fileprivate let endpointURL = URL(string: "https://us-central1-gold-stone-332203.cloudfunctions.net/receiptEntitlement")!


struct ReceiptMigrationView: View {
  var process: ReceiptMigrationProgress
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      switch(process.state) {
      case .working:
        Text("Receipt migration in progress.")
      case .receiptFetchFailure:
        Text("Could not fetch the receipt for the app.")
        Button(action: process.load, label: { Text("Please try again.")} )
      case .requestFailure:
        Text("Error performing your migration request.")
        Button(action: process.load, label: { Text("Please try again.") })
      case .migrationFailure(let error):
        Text("Could not migrate your token.")
        //Text("\(error)")
      case .done:
        Text("Done")
          .onAppear(perform: { presentationMode.wrappedValue.dismiss() })
      }
    }
    .onAppear(perform: process.load)
  }
}

class ReceiptMigrationProgress: ObservableObject {
  var receiptOperation: AnyCancellable? = nil
  let originalUserId: String
  @Published var state = Status.working

  enum Status {
    case working
    case done
    case requestFailure
    case receiptFetchFailure
    case migrationFailure(ReceiptMigrationError)
  }

  init(originalUserId: String) {
    self.originalUserId = originalUserId
  }

  func load() {
    receiptOperation = SKStore()
      .fetchReceiptURLPublisher()
      .tryMap { receiptURL -> String in
        let d = try Data(contentsOf: receiptURL, options: .alwaysMapped)
        let receipt = d.base64EncodedString(options: [])
        return receipt
      }
      //Just("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")
      .flatMap { MigrationToken.requestTokenForMigration(receipt: $0, attachedTo: self.originalUserId) }
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { completion in
          // If successful, dismiss yourself
          // Show errors and let the user dismiss
          print(completion)
          switch completion {
          case .finished:
            self.state = .done
          case .failure(let error):
            print("Error performing request token migration - \(error)")
            switch error {
            case ReceiptMigrationError.requestError,
              SKStoreError.fetchError:
              self.state = .requestFailure
            case is ReceiptMigrationError:
              self.state = .migrationFailure(error as! ReceiptMigrationError)
            case is SKStoreError:
              self.state = .receiptFetchFailure
            default:
              self.state = .requestFailure
            }
          }
        },
        receiveValue: { migrationToken in
          // Open blinkv15 with received value
          let migrationTokenString = migrationToken.base64EncodedString()
          let migrationTokenUrl = URL(string: "blinkv15://validateReceipt?migrationToken=\(migrationTokenString)")!
          UIApplication.shared.open(migrationTokenUrl) // { result in } // Alert if it cannot callback?
        }
      )
  }
}

struct ReceiptMigrationOfferingView: View {
  enum Status {
    case validating
    case accepted
    case denied(error: Error)
  }

  var encodedMigrationToken: Data
  let originalUserId = Purchases.shared.appUserID
  @State var migrationStatus = Status.validating

  var body: some View {
    VStack {
      switch(migrationStatus) {
        case .validating:
        Text("Validating...")
        case .accepted:
        Text("Hurray!!")
        case .denied(let error):
        Text("Invalid Migration Token \(error.localizedDescription)")
      }
    }
    .onAppear(perform: {
      do {
        let migrationToken = try JSONDecoder().decode(MigrationToken.self, from: encodedMigrationToken)
        try migrationToken.validateReceiptForMigration(attachedTo: originalUserId)
        migrationStatus = .accepted
      } catch {
        migrationStatus = .denied(error: error)
      }
    })
  }
}

struct MigrationToken: Codable {
  let token: String
  let data:  String

  public static func requestTokenForMigration(receipt: String, attachedTo originalUserId: String) -> AnyPublisher<Data, Error> {
    Just(["receiptData": receipt,
          "originalUserId": originalUserId])
  // NOTE Leaving this for reference. This is now responsibility of other layers.
  //  SKStore()
  //    .fetchReceiptURLPublisher()
  //    .tryMap { receiptURL -> [String:String] in
  //      let d = try Data(contentsOf: receiptURL, options: .alwaysMapped)
  //      let receipt = d.base64EncodedString(options: [])
  //      return  ["receiptData": receipt,
  //               "originalUserId": originalUserId]
  //    }
      .encode(encoder: JSONEncoder())
      .map { data -> URLRequest in
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        return request
      }
      .flatMap {
        URLSession.shared.dataTaskPublisher(for: $0)
        .tryMap { element -> Data in
          guard let httpResponse = element.response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
          }
          let statusCode = httpResponse.statusCode
          guard statusCode == 200 else {
            let errorMessage = try? JSONDecoder().decode(ErrorMessage.self, from: element.data)
            switch statusCode {
              case 409:
              throw ReceiptMigrationError.receiptExists(errorMessage)
              case 400:
              throw ReceiptMigrationError.invalidAppReceipt(errorMessage)
              default:
              throw ReceiptMigrationError.requestError(errorMessage)
            }
          }
          return element.data
        }
      }
      .eraseToAnyPublisher()
  }

  public func validateReceiptForMigration(attachedTo originalUserId: String) throws {
    // TODO We need to use a different separator, as actually RevCat is using the colon.
    let dataComponents = data.components(separatedBy: ":")
    let currentTimestamp = Int(Date().timeIntervalSince1970)

    // Check the user coming from signature and params match.
    // Check the timestamp is within a range, to prevent reuse.
    guard dataComponents.count == 4,
      "\(dataComponents[1]):\(dataComponents[2])" == originalUserId,
      let receiptTimestamp = Int(dataComponents[3]),
      // 60s margin for timestamp. It is rare that it takes more than 15 secs.
      (currentTimestamp - receiptTimestamp) < 60 else {
        throw ReceiptMigrationError.invalidMigrationReceipt
      }
    guard isSignatureVerified else {
      throw ReceiptMigrationError.invalidMigrationReceiptSignature
    }
  }

  private let publicKeyStr = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEO5gruKzo5hnh8eiaakwZgliooXEWS+0180oEeF2m1jUtTlje6AL/ybNTkXdAtxz3DtBUEGI9VIVvtN5eNBYbpg=="
  //private let publicKeyStr = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEsuI2ZyUFD45NRAH4OEu4GvrOmdv4X4Ti49pbhbLY2fvQNEHI6fp/5Ndawwnp5uK2GIDk0e1E//uV3GEiPT8vOA=="
  private var publicKey: CryptoKit.P256.Signing.PublicKey {
    get {
      let pemKeyData = Data(base64Encoded: publicKeyStr)!

      return (pemKeyData.withUnsafeBytes { bytes in
        return try! CryptoKit.P256.Signing.PublicKey(derRepresentation: bytes)
      })
    }
  }

  private var isSignatureVerified: Bool {
    guard
      let data = data.data(using: .utf8),
      let signedRawRS = Data(base64Encoded: token),
      let signature = try? CryptoKit.P256.Signing
        .ECDSASignature(rawRepresentation: signedRawRS) else {
      return false
    }

    return publicKey.isValidSignature(signature, for: data as NSData)
  }
}

struct ErrorMessage: Codable {
  let error: String
}

enum ReceiptMigrationError: Error {
  // 409 - we may want to drop the ID in this scenario.
  case receiptExists(ErrorMessage?)
  // 40X
  case invalidAppReceipt(ErrorMessage?)
  case invalidMigrationReceipt
  case invalidMigrationReceiptSignature
  // Everything else
  case requestError(ErrorMessage?)
}

enum SKStoreError: Error {
  case notFound
  case fetchError
  case requestError(Error)
}

@objc class SKStore: NSObject {
  var done: ((URL?, Error?) -> Void)!
  var skReq: SKReceiptRefreshRequest? = nil

  func fetchReceiptURLPublisher() -> AnyPublisher<URL, Error> {
    return Future<URL, Error> { promise in
      self.fetchReceiptURL { (url, error) in
        if let url = url {
          promise(.success(url))
        } else {
          promise(.failure(error ?? SKStoreError.fetchError))
        }
      }
    }.eraseToAnyPublisher()
  }

  func fetchReceiptURL(_ done: @escaping (URL?, Error?) -> Void) {
    self.done = done

    guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
      return done(nil, SKStoreError.notFound)
    }
    if !FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
      let skReq = SKReceiptRefreshRequest(receiptProperties: nil)
      skReq.delegate = self
      skReq.start()
      self.skReq = skReq
    } else {
      done(appStoreReceiptURL, nil)
    }

  }
}

extension SKStore: SKRequestDelegate {
  func requestDidFinish(_ request: SKRequest) {
    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
       FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
      return done(appStoreReceiptURL, nil)
    } else {
      return done(nil, SKStoreError.notFound)
    }
  }
  func request(_ request: SKRequest, didFailWithError error: Error) {
    return done(nil, SKStoreError.requestError(error))
  }
}
