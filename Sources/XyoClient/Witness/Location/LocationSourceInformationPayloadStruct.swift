import CoreLocation
import Foundation

struct LocationSourceInformationPayloadStruct: Encodable {

    var sourceInformation: CLLocationSourceInformation

    init(_ sourceInformation: CLLocationSourceInformation) {
        self.sourceInformation = sourceInformation
    }

    enum CodingKeys: String, CodingKey {
        case isProducedByAccessory
        case isSimulatedBySoftware
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.sourceInformation.isProducedByAccessory, forKey: .isProducedByAccessory)
        try container.encode(self.sourceInformation.isSimulatedBySoftware, forKey: .isSimulatedBySoftware)
    }
}
