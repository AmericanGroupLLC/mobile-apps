import XCTest
@testable import PocketCore

final class CalculatorEngineTests: XCTestCase {
    func test_basic_arithmetic() {
        XCTAssertEqual(CalculatorEngine.evaluate("2+3*4"), .number(14))
        XCTAssertEqual(CalculatorEngine.evaluate("(1+2)*(3+4)"), .number(21))
        XCTAssertEqual(CalculatorEngine.evaluate("10-3-2"), .number(5))
        XCTAssertEqual(CalculatorEngine.evaluate("100/4/5"), .number(5))
    }

    func test_unicode_operators() {
        XCTAssertEqual(CalculatorEngine.evaluate("2×3"), .number(6))
        XCTAssertEqual(CalculatorEngine.evaluate("8÷2"), .number(4))
        XCTAssertEqual(CalculatorEngine.evaluate("5−3"), .number(2))
    }

    func test_unary_minus() {
        XCTAssertEqual(CalculatorEngine.evaluate("-3+5"), .number(2))
        XCTAssertEqual(CalculatorEngine.evaluate("-(2+3)"), .number(-5))
        XCTAssertEqual(CalculatorEngine.evaluate("4*-2"), .number(-8))
    }

    func test_scientific() {
        if case .number(let v) = CalculatorEngine.evaluate("sin(pi/2)") {
            XCTAssertEqual(v, 1.0, accuracy: 1e-9)
        } else { XCTFail() }
        if case .number(let v) = CalculatorEngine.evaluate("cos(0)") {
            XCTAssertEqual(v, 1.0, accuracy: 1e-9)
        } else { XCTFail() }
        XCTAssertEqual(CalculatorEngine.evaluate("2^10"), .number(1024))
        if case .number(let v) = CalculatorEngine.evaluate("sqrt(2)") {
            XCTAssertEqual(v, 1.4142135, accuracy: 1e-5)
        } else { XCTFail() }
        if case .number(let v) = CalculatorEngine.evaluate("ln(e)") {
            XCTAssertEqual(v, 1.0, accuracy: 1e-9)
        } else { XCTFail() }
        if case .number(let v) = CalculatorEngine.evaluate("log(100)") {
            XCTAssertEqual(v, 2.0, accuracy: 1e-9)
        } else { XCTFail() }
    }

    func test_unicode_sqrt_and_pi() {
        if case .number(let v) = CalculatorEngine.evaluate("√2") {
            XCTAssertEqual(v, 1.4142135, accuracy: 1e-5)
        } else { XCTFail() }
        if case .number(let v) = CalculatorEngine.evaluate("π") {
            XCTAssertEqual(v, .pi, accuracy: 1e-12)
        } else { XCTFail() }
    }

    func test_divide_by_zero() {
        if case .error = CalculatorEngine.evaluate("5/0") { } else { XCTFail() }
        if case .error = CalculatorEngine.evaluate("5%0") { } else { XCTFail() }
    }

    func test_invalid_expressions() {
        if case .error = CalculatorEngine.evaluate("(1+2") { } else { XCTFail() }
        if case .error = CalculatorEngine.evaluate("1++2") { } else { XCTFail() }
        if case .error = CalculatorEngine.evaluate("foo(1)") { } else { XCTFail() }
    }
}
