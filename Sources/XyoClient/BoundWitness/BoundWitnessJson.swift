import Foundation

public class XyoBoundWitnessJson: XyoBoundWitnessBodyJson, XyoBoundWitnessMetaProtocol {
    enum CodingKeys: String, CodingKey {
        case addresses
        case previous_hashes
        case payload_hashes
        case payload_schemas
        case _signatures
        case _client
        case _hash
    }
    
    public var _signatures: [String]?
    public var _payloads: [Codable]?
    public var _client: String?
    public var _hash: String?
    
    func encodeMetaFields(_ container: inout KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(_signatures, forKey: ._signatures)
        try container.encode(_client, forKey: ._client)
        try container.encode(_hash, forKey: ._hash)
    }
    
    func encodeBodyFields(_ container: inout KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(addresses, forKey: .addresses)
        try container.encode(previous_hashes, forKey: .previous_hashes)
        try container.encode(payload_hashes, forKey: .payload_hashes)
        try container.encode(payload_schemas, forKey: .payload_schemas)
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeBodyFields(&container)
        try encodeMetaFields(&container)
    }
}