import Foundation

// MARK: - Archivable Classes with stable Obj-C names

@objc(WKWF)
fileprivate class _WFWorkflow: NSObject, NSCoding {
    let dict: [String: Any]
    init(_ dict: [String: Any]) { self.dict = dict; super.init() }
    required init?(coder: NSCoder) { fatalError() }
    func encode(with coder: NSCoder) {
        for (k, v) in dict {
            if let obj = v as? NSObject { coder.encode(obj, forKey: k) }
        }
    }
}

@objc(WKAC)
fileprivate class _WFACtion: _WFWorkflow {}

@objc(WKIC)
fileprivate class _WFIcon: _WFWorkflow {}

// MARK: - Shortcut Generator

class ShortcutGenerator {
    
    /// Generate shortcut data for: Take Screenshot → Open URL bills://process
    static func generateShortcutData() -> Data? {
        NSKeyedArchiver.setClassName("WFWorkflow", for: _WFWorkflow.self)
        NSKeyedArchiver.setClassName("WFACtion", for: _WFACtion.self)
        NSKeyedArchiver.setClassName("WFWorkflowIcon", for: _WFIcon.self)
        
        let tsAction = _WFACtion([
            "WFWorkflowActionIdentifier": "com.apple.shortcuts.action.TakeScreenshot" as NSString,
            "WFWorkflowActionParameters": NSDictionary()
        ])
        
        let urlAction = _WFACtion([
            "WFWorkflowActionIdentifier": "is.workflow.actions.openurl" as NSString,
            "WFWorkflowActionParameters": NSDictionary(dictionary: [
                "WFURLActionURL": "bills://process" as NSString,
                "WFAskWhenRun": NSNumber(value: false)
            ])
        ])
        
        let actions = NSArray(objects: tsAction, urlAction)
        
        let icon = _WFIcon([
            "WFWorkflowIconGlyphNumber": NSNumber(value: 59723),
            "WFWorkflowIconStartColor": NSNumber(value: 1440408063),
            "WFWorkflowIconImageData": NSData()
        ])
        
        let workflow = _WFWorkflow([
            "WFWorkflowActions": actions,
            "WFWorkflowIcon": icon,
            "WFWorkflowMinimumClientVersion": NSNumber(value: 900),
            "WFWorkflowClientRelease": "17.0" as NSString,
            "WFWorkflowTypes": NSArray(array: [NSNumber(value: 1), NSNumber(value: 2)]),
            "WFWorkflowImportQuestions": NSArray(),
            "WFWorkflowHasShortcutInputVariables": NSNumber(value: false),
        ])
        
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.setClassName("WFWorkflow", for: _WFWorkflow.self)
        archiver.setClassName("WFACtion", for: _WFACtion.self)
        archiver.setClassName("WFWorkflowIcon", for: _WFIcon.self)
        archiver.outputFormat = .binary
        archiver.encode(workflow, forKey: "root")
        
        return archiver.encodedData
    }
    
    static func generateShortcutFile() -> URL? {
        guard let data = generateShortcutData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("记账助手_\(UUID().uuidString.prefix(8)).shortcut")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
