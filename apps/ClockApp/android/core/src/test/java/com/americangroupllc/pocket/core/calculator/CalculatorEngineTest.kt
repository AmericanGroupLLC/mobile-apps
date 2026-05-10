package com.americangroupllc.pocket.core.calculator

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import kotlin.math.PI
import kotlin.math.E

class CalculatorEngineTest {

    private fun number(r: CalcResult): Double {
        require(r is CalcResult.Number) { "Expected number, got $r" }
        return r.value
    }

    @Test fun `basic arithmetic`() {
        assertThat(number(CalculatorEngine.evaluate("2+3*4"))).isEqualTo(14.0)
        assertThat(number(CalculatorEngine.evaluate("(1+2)*(3+4)"))).isEqualTo(21.0)
        assertThat(number(CalculatorEngine.evaluate("10-3-2"))).isEqualTo(5.0)
        assertThat(number(CalculatorEngine.evaluate("100/4/5"))).isEqualTo(5.0)
    }

    @Test fun `unicode operators`() {
        assertThat(number(CalculatorEngine.evaluate("2×3"))).isEqualTo(6.0)
        assertThat(number(CalculatorEngine.evaluate("8÷2"))).isEqualTo(4.0)
        assertThat(number(CalculatorEngine.evaluate("5−3"))).isEqualTo(2.0)
    }

    @Test fun `unary minus`() {
        assertThat(number(CalculatorEngine.evaluate("-3+5"))).isEqualTo(2.0)
        assertThat(number(CalculatorEngine.evaluate("-(2+3)"))).isEqualTo(-5.0)
        assertThat(number(CalculatorEngine.evaluate("4*-2"))).isEqualTo(-8.0)
    }

    @Test fun `scientific functions`() {
        assertThat(number(CalculatorEngine.evaluate("sin(pi/2)"))).isWithin(1e-9).of(1.0)
        assertThat(number(CalculatorEngine.evaluate("cos(0)"))).isWithin(1e-9).of(1.0)
        assertThat(number(CalculatorEngine.evaluate("2^10"))).isEqualTo(1024.0)
        assertThat(number(CalculatorEngine.evaluate("sqrt(2)"))).isWithin(1e-5).of(1.4142135)
        assertThat(number(CalculatorEngine.evaluate("ln(e)"))).isWithin(1e-9).of(1.0)
        assertThat(number(CalculatorEngine.evaluate("log(100)"))).isWithin(1e-9).of(2.0)
    }

    @Test fun `unicode sqrt and pi`() {
        assertThat(number(CalculatorEngine.evaluate("√2"))).isWithin(1e-5).of(1.4142135)
        assertThat(number(CalculatorEngine.evaluate("π"))).isWithin(1e-12).of(PI)
    }

    @Test fun `divide by zero is an error`() {
        assertThat(CalculatorEngine.evaluate("5/0")).isInstanceOf(CalcResult.Error::class.java)
        assertThat(CalculatorEngine.evaluate("5%0")).isInstanceOf(CalcResult.Error::class.java)
    }

    @Test fun `invalid expressions return error`() {
        assertThat(CalculatorEngine.evaluate("(1+2")).isInstanceOf(CalcResult.Error::class.java)
        assertThat(CalculatorEngine.evaluate("1++2")).isInstanceOf(CalcResult.Error::class.java)
        assertThat(CalculatorEngine.evaluate("foo(1)")).isInstanceOf(CalcResult.Error::class.java)
    }

    @Test fun `e constant works`() {
        assertThat(number(CalculatorEngine.evaluate("e"))).isWithin(1e-12).of(E)
    }
}
