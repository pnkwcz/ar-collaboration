//
//  ServerAPI.swift
//  colab
//
//  Created by Artur Pinkevych on 03/09/2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import ARKit

extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let columns = try (0..<4).map { _ in try container.decode(simd_float4.self) }
        self.init(columns)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try (0..<4).forEach { try container.encode(self[$0]) }
    }
}

struct AnchorData: Codable {
    let id: String
    let name: String
    let transform: simd_float4x4
}

class ServerAPI {
    static let shared = ServerAPI()
    
    private let baseURL = "http://192.168.100.3:3000"
    
    func addAnchor(anchor: ARAnchor, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/addAnchor") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let anchorData = AnchorData(id: anchor.identifier.uuidString, name: anchor.name ?? "Unnamed", transform: anchor.transform)
        
        do {
            let jsonData = try JSONEncoder().encode(anchorData)
            request.httpBody = jsonData
        } catch {
            print("Error encoding anchor data: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending anchor to server: \(error)")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    func getAnchors(completion: @escaping ([AnchorData]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/getAnchors") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error retrieving anchors from server: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let anchors = try JSONDecoder().decode([AnchorData].self, from: data)
                completion(anchors)
            } catch {
                print("Error decoding anchor data: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
