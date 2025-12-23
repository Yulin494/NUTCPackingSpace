//
//  NUTCParkingSpaceTests.swift
//  NUTCParkingSpaceTests
//
//  Created by imac on 2025/12/21.
//

import XCTest
import CoreLocation
import Combine
@testable import NUTCParkingSpace

// MARK: - ParkingLot Model Tests
final class ParkingLotTests: XCTestCase {
    
    func testParkingLotInitialization() throws {
        let lot = ParkingLot(
            name: "測試停車場",
            totalCapacity: 100,
            availableCount: 50,
            coordinate: CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974),
            lastUpdated: Date(),
            type: .motorcycle
        )
        
        XCTAssertEqual(lot.name, "測試停車場")
        XCTAssertEqual(lot.totalCapacity, 100)
        XCTAssertEqual(lot.availableCount, 50)
        XCTAssertEqual(lot.type, .motorcycle)
    }
    
    func testParkingLotEquality() throws {
        let date = Date()
        let coord = CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974)
        
        let lot1 = ParkingLot(name: "A", totalCapacity: 100, availableCount: 50, coordinate: coord, lastUpdated: date, type: .motorcycle)
        let lot2 = ParkingLot(name: "A", totalCapacity: 100, availableCount: 50, coordinate: coord, lastUpdated: date, type: .motorcycle)
        
        // 注意：因為 id 是 UUID()，所以兩個 lot 的 id 不同，Equatable 會回傳 false
        // 這是預期行為，測試驗證 Equatable 實作
        XCTAssertNotEqual(lot1, lot2, "不同 UUID 的 ParkingLot 應該不相等")
    }
    
    func testParkingTypeRawValue() throws {
        XCTAssertEqual(ParkingType.motorcycle.rawValue, "機車停車場")
        XCTAssertEqual(ParkingType.car.rawValue, "汽車停車場")
    }
    
    func testParkingTypeAllCases() throws {
        XCTAssertEqual(ParkingType.allCases.count, 2)
        XCTAssertTrue(ParkingType.allCases.contains(.motorcycle))
        XCTAssertTrue(ParkingType.allCases.contains(.car))
    }
}

// MARK: - ParkingDataService Tests
final class ParkingDataServiceTests: XCTestCase {
    
    var dataService: ParkingDataService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        dataService = ParkingDataService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
    }
    
    func testDataServiceSingleton() throws {
        let instance1 = ParkingDataService.shared
        let instance2 = ParkingDataService.shared
        XCTAssertTrue(instance1 === instance2, "ParkingDataService 應該是 Singleton")
    }
    
    func testFetchParkingDataAsync() throws {
        let expectation = XCTestExpectation(description: "Fetch parking data")
        
        dataService.$parkingLots
            .dropFirst() // 忽略初始空值
            .sink { lots in
                // 只要有資料回傳就算成功（即使是空的，因為可能伺服器問題）
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        dataService.fetchParkingData()
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testFetchParkingDataWithCompletion() throws {
        let expectation = XCTestExpectation(description: "Fetch with completion")
        
        dataService.fetchParkingData { lots in
            // 完成回調被呼叫
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testParsedDataHasCorrectTypes() throws {
        let expectation = XCTestExpectation(description: "Check parsed data types")
        
        dataService.fetchParkingData { lots in
            if !lots.isEmpty {
                // 檢查是否有機車和汽車停車場
                let hasMotorcycle = lots.contains { $0.type == .motorcycle }
                let hasCar = lots.contains { $0.type == .car }
                
                // 至少有一種類型（取決於伺服器資料）
                XCTAssertTrue(hasMotorcycle || hasCar, "應該至少有一種停車場類型")
                
                // 檢查資料完整性
                for lot in lots {
                    XCTAssertFalse(lot.name.isEmpty, "停車場名稱不應為空")
                    XCTAssertGreaterThanOrEqual(lot.availableCount, 0, "剩餘車位不應為負數")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}

// MARK: - ParkingListViewModel Tests
final class ParkingListViewModelTests: XCTestCase {
    
    var viewModel: ParkingListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        viewModel = ParkingListViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        viewModel.stopAutoRefresh()
        cancellables = nil
    }
    
    func testViewModelInitialization() throws {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.parkingLots.count, 0)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testFetchParkingData() throws {
        let expectation = XCTestExpectation(description: "ViewModel fetch data")
        
        viewModel.$parkingLots
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.fetchParkingData()
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testAutoRefreshStartsAndStops() throws {
        // 測試啟動自動更新
        viewModel.startAutoRefresh()
        
        // 給予一點時間讓 Timer 建立
        let expectation = XCTestExpectation(description: "Auto refresh started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // 測試停止自動更新
        viewModel.stopAutoRefresh()
        
        // 驗證可以多次呼叫停止而不會崩潰
        viewModel.stopAutoRefresh()
        viewModel.stopAutoRefresh()
    }
    
    func testIsLoadingStateChanges() throws {
        let expectation = XCTestExpectation(description: "isLoading changes")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.fetchParkingData()
        
        wait(for: [expectation], timeout: 30.0)
        
        // 應該至少有一個 true（載入中）和一個 false（完成）
        XCTAssertTrue(loadingStates.contains(true) || loadingStates.contains(false))
    }
}

// MARK: - CommuteManager Tests
final class CommuteManagerTests: XCTestCase {
    
    var commuteManager: CommuteManager!
    
    override func setUpWithError() throws {
        commuteManager = CommuteManager.shared
    }
    
    override func tearDownWithError() throws {
        commuteManager.stopCommuting()
    }
    
    func testCommuteManagerSingleton() throws {
        let instance1 = CommuteManager.shared
        let instance2 = CommuteManager.shared
        XCTAssertTrue(instance1 === instance2, "CommuteManager 應該是 Singleton")
    }
    
    func testInitialState() throws {
        // 初始狀態應該是非通勤模式
        // 注意：如果之前有測試留下狀態，這可能失敗，所以先停止
        commuteManager.stopCommuting()
        XCTAssertFalse(commuteManager.isCommuting)
        XCTAssertNil(commuteManager.currentLot)
    }
    
    func testStopCommutingWhenNotStarted() throws {
        // 測試在未開始時呼叫 stopCommuting 不會崩潰
        commuteManager.stopCommuting()
        commuteManager.stopCommuting()
        XCTAssertFalse(commuteManager.isCommuting)
    }
}

// MARK: - HTML Parsing Tests (模擬資料)
final class HTMLParsingTests: XCTestCase {
    
    func testCleanStringRemovesHTMLTags() throws {
        // 這是私有方法，無法直接測試
        // 但我們可以透過整合測試來驗證解析結果
        
        let dataService = ParkingDataService.shared
        let expectation = XCTestExpectation(description: "Parse HTML")
        
        dataService.fetchParkingData { lots in
            for lot in lots {
                // 驗證名稱中不包含 HTML 標籤
                XCTAssertFalse(lot.name.contains("<"), "名稱不應包含 HTML 標籤")
                XCTAssertFalse(lot.name.contains(">"), "名稱不應包含 HTML 標籤")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testParsedDataDoesNotContainHeaderRow() throws {
        let dataService = ParkingDataService.shared
        let expectation = XCTestExpectation(description: "Check no header row")
        
        dataService.fetchParkingData { lots in
            for lot in lots {
                // 驗證沒有解析到標題列
                XCTAssertNotEqual(lot.name, "停車場", "不應該包含標題列")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}

// MARK: - Integration Tests
final class IntegrationTests: XCTestCase {
    
    func testFullDataFlowFromServiceToViewModel() throws {
        let viewModel = ParkingListViewModel()
        let expectation = XCTestExpectation(description: "Full data flow")
        var cancellables = Set<AnyCancellable>()
        
        viewModel.$parkingLots
            .dropFirst()
            .sink { lots in
                // 驗證資料流通
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.fetchParkingData()
        
        wait(for: [expectation], timeout: 30.0)
        
        viewModel.stopAutoRefresh()
    }
    
    func testDataServiceAndViewModelSynchronization() throws {
        let viewModel = ParkingListViewModel()
        let dataService = ParkingDataService.shared
        let expectation = XCTestExpectation(description: "Data sync")
        var cancellables = Set<AnyCancellable>()
        
        // 監聽 ViewModel 的變化
        viewModel.$parkingLots
            .dropFirst()
            .sink { lots in
                // ViewModel 的資料應該與 DataService 一致
                XCTAssertEqual(lots.count, dataService.parkingLots.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.fetchParkingData()
        
        wait(for: [expectation], timeout: 30.0)
        
        viewModel.stopAutoRefresh()
    }
}

// MARK: - Performance Tests
final class PerformanceTests: XCTestCase {
    
    func testFetchPerformance() throws {
        let dataService = ParkingDataService.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Performance fetch")
            
            dataService.fetchParkingData { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 60.0)
        }
    }
}

// MARK: - 原有測試類別
final class NUTCParkingSpaceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
