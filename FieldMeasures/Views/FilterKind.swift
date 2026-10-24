import Foundation

/// The filter choice shown in the picker; Custom takes its dates from a separate `CustomRange`.
enum FilterKind: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .today: "Today"
        case .last7Days: "7 Days"
        case .custom: "Custom"
        }
    }

    func filter(custom range: CustomRange) -> DateFilter {
        switch self {
        case .all: .all
        case .today: .today
        case .last7Days: .last7Days
        case .custom: .custom(range)
        }
    }
}
