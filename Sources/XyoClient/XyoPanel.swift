import Foundation

public enum XyoPanelError: Error {
    case postToArchivistFailed
}

public class XyoPanel {
    
    public init(archivists: [XyoArchivistApiClient], witnesses: [XyoWitness]) {
        self._archivists = archivists
        self._witnesses = witnesses
    }
    
    public convenience init(archive: String? = nil, apiDomain: String? = nil, witnesses: [XyoWitness]? = nil, token: String? = nil) {
        let apiConfig = XyoArchivistApiConfig(archive ?? XyoPanel.Defaults.apiModule, apiDomain ?? XyoPanel.Defaults.apiDomain)
        let archivist = XyoArchivistApiClient.get(apiConfig)
        self.init(archivists: [archivist], witnesses: witnesses ?? [])
    }
    
    public convenience init(observe: ((_ previousHash: String?) -> XyoEventPayload?)?) {
        if observe != nil {
            var witnesses = [XyoWitness]()
            
            if let observe = observe {
                witnesses.append(XyoEventWitness(observe))
            }
            
            self.init(witnesses: witnesses)
        } else {
            self.init()
        }
    }
    
    public typealias XyoPanelReportCallback = (([String]) -> Void)
    
    private var _archivists: [XyoArchivistApiClient]
    private var _witnesses: [XyoWitness]
    private var _previous_hash: String?
    
    public func report() throws -> [XyoPayload] {
        try report(nil)
    }
    
    public func event(_ event: String, _ closure: XyoPanelReportCallback?) throws -> [XyoPayload] {
        try report([XyoEventWitness { previousHash in XyoEventPayload(event, previousHash) }], closure)
    }
    
    public func report(_ adhocWitnesses: [XyoWitness], _ closure: XyoPanelReportCallback?) throws -> [XyoPayload] {
        var witnesses: [XyoWitness] = []
        witnesses.append(contentsOf: adhocWitnesses)
        witnesses.append(contentsOf: self._witnesses)
        let payloads = witnesses.map { witness in
            witness.observe()
        }
        let bw = try BoundWitnessBuilder()
            .payloads(payloads.compactMap { $0 })
            .witnesses(witnesses)
            .build(_previous_hash)
        self._previous_hash = bw._hash
        var errors: [String] = []
        var archivistCount = _archivists.count
        try _archivists.forEach { archivist in
            try archivist.postBoundWitness(bw) { error in
                archivistCount = archivistCount - 1
                if let errorExists = error {
                    errors.append(errorExists)
                }
                if archivistCount == 0 {
                    closure?(errors)
                }
            }
        }
        return payloads.compactMap { $0 }
    }
    
    public func report(_ closure: XyoPanelReportCallback?) throws -> [XyoPayload] {
        return try self.report([], closure)
    }
    
    struct Defaults {
        static let apiModule = "Archivist"
        static let apiDomain = "https://beta.api.archivist.xyo.network"
    }
    
    private static var defaultArchivist: XyoArchivistApiClient {
        XyoArchivistApiClient.get(XyoArchivistApiConfig(self.Defaults.apiModule, self.Defaults.apiDomain))
    }
}
