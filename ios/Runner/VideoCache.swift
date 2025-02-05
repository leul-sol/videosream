import Foundation
import AVFoundation

@objc class VideoCache: NSObject {
    static let shared = VideoCache()
    private let cache = NSCache<NSString, AVAssetResourceLoader>()
    private let maxCacheSize: Int = 500 * 1024 * 1024 // 500MB
    
    override init() {
        super.init()
        cache.totalCostLimit = maxCacheSize
    }
    
    @objc func preloadVideo(url: String) {
        let asset = AVURLAsset(url: URL(string: url)!)
        let keys = ["playable"]
        asset.loadValuesAsynchronously(forKeys: keys) {}
        cache.setObject(asset.resourceLoader, forKey: url as NSString)
    }
    
    @objc func clearCache() {
        cache.removeAllObjects()
    }
}

