import XCTest
@testable import FitFusionCore

final class NutritionLabelOCRTests: XCTestCase {

    func testExtractsCalories() {
        let text = """
        Nutrition Facts
        Serving size 1 cup
        Calories 230
        Total Fat 8g
        Total Carbohydrate 37g
        Protein 3g
        """
        let result = NutritionLabelOCR.extract(from: text)
        XCTAssertEqual(result.kcal, 230)
        XCTAssertEqual(result.fatG, 8)
        XCTAssertEqual(result.carbsG, 37)
        XCTAssertEqual(result.proteinG, 3)
    }

    func testHandlesCommaDecimal() {
        let text = "Total Fat 1,5g\nCalories 110"
        let result = NutritionLabelOCR.extract(from: text)
        XCTAssertEqual(result.fatG, 1.5)
        XCTAssertEqual(result.kcal, 110)
    }

    func testDetectsBarcode() {
        let text = "Calories 200\nUPC: 0123456789012"
        let result = NutritionLabelOCR.extract(from: text)
        XCTAssertEqual(result.detectedBarcode, "0123456789012")
    }

    func testReturnsNilsWhenLabelMissing() {
        let result = NutritionLabelOCR.extract(from: "no nutrition info here")
        XCTAssertNil(result.kcal)
        XCTAssertNil(result.proteinG)
    }
}
