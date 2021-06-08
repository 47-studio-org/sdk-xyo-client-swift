import Foundation

public enum XyoPanelError: Error {
    case postToArchivistFailed
}

public class XyoPanel {
    
    public init(archivists: [XyoArchivistApiClient], witnesses: [XyoWitness]) {
        self._archivists = archivists
        self._witnesses = witnesses
    }
    
    public convenience init(archive: String? = nil, apiDomain: String? = nil, witnesses: [XyoWitness]? = nil, token: String? = nil) throws {
        let apiConfig = XyoArchivistApiConfig(archive ?? XyoPanel.Defaults.apiArchive, apiDomain ?? XyoPanel.Defaults.apiDomain)
        let archivist = XyoArchivistApiClient.get(apiConfig)
        try self.init(archivists: [archivist], witnesses: witnesses ?? [XyoWitness(try XyoAddress())])
    }
    
    public convenience init(observe: (() -> XyoPayload?)?) throws {
        if (observe != nil) {
            try self.init(witnesses: [XyoBasicWitness(observe!)])
        } else {
            try self.init()
        }
    }
    
    public typealias XyoPanelReportCallback = (([Error])->Void)
    
    private var _archivists: [XyoArchivistApiClient]
    private var _witnesses: [XyoWitness]
    
    public func report(closure:@escaping XyoPanelReportCallback) throws {
        let payloads = self._witnesses.map { witness in
            witness.observe()
        }
        let bw = try BoundWitnessBuilder()
            .payloads(payloads.compactMap { $0 })
            .witnesses(self._witnesses)
            .build()
        var errors: [Error] = []
        var archivistCount = _archivists.count
        try _archivists.forEach { archivist in
            try archivist.postBoundWitness(bw) { count, error in
                archivistCount = archivistCount - 1
                if let errorExists = error {
                    errors.append(errorExists)
                }
                if (archivistCount == 0) {
                    closure(errors)
                }
            }
        }
    }
    
    struct Defaults {
        static let apiArchive = "default"
        static let apiDomain = "https://archivist.xyo.network"
    }
    
    private static var defaultArchivist: XyoArchivistApiClient {
        get {
            let apiConfig = XyoArchivistApiConfig(self.Defaults.apiArchive, self.Defaults.apiDomain)
            return XyoArchivistApiClient.get(apiConfig)
        }
    }
}