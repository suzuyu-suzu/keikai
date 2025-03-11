// HealthKitManager.swift

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private var healthStore: HKHealthStore?
    @Published var isAuthorized = false
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            checkAuthorization()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(false)
            return
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepsType, distanceType]) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success)
            }
        }
    }
    
    private func checkAuthorization() {
        guard let healthStore = healthStore else { return }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.getRequestStatusForAuthorization(toShare: [], read: [stepsType]) { status, error in
            DispatchQueue.main.async {
                self.isAuthorized = status == .unnecessary
            }
        }
    }
    
    // 歩数を取得する（指定期間）
    func fetchSteps(startDate: Date, endDate: Date, completion: @escaping (Int) -> Void) {
        guard let healthStore = healthStore,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(Int(sum.doubleValue(for: HKUnit.count())))
            }
        }
        
        healthStore.execute(query)
    }
    
    // 歩行距離を取得する（指定期間）
    func fetchDistance(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let healthStore = healthStore,
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            DispatchQueue.main.async {
                // キロメートル単位で取得
                completion(sum.doubleValue(for: HKUnit.meterUnit(with: .kilo)))
            }
        }
        
        healthStore.execute(query)
    }
}
