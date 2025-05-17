import Foundation
import FirebaseFirestore

struct WeightLog: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let weight: Double
    let date: Date
    let note: String?
    
    static func hasLoggedToday(logs: [WeightLog]) -> Bool {
        guard let lastLog = logs.sorted(by: { $0.date > $1.date }).first else {
            return false
        }
        
        return Calendar.current.isDateInToday(lastLog.date)
    }
}