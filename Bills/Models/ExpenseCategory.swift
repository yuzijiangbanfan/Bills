import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "餐饮·吃饭"
    case snacks = "零食·饮料"
    case fuel = "交通·加油"
    case clothing = "购物·买衣服"
    case daily = "日用·家居"
    case entertainment = "娱乐·游戏"
    case housing = "住房·水电"
    case health = "医疗·健康"
    case education = "学习·教育"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .snacks: return "cup.and.saucer.fill"
        case .fuel: return "car.fill"
        case .clothing: return "tshirt.fill"
        case .daily: return "house.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "bolt.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var tint: String {
        switch self {
        case .food: return "FF6B6B"
        case .snacks: return "FF9F43"
        case .fuel: return "54A0FF"
        case .clothing: return "5F27CD"
        case .daily: return "00D2D3"
        case .entertainment: return "F368E0"
        case .housing: return "FF9FF3"
        case .health: return "26DE81"
        case .education: return "48DBFB"
        case .other: return "8395A7"
        }
    }
}
