module vdecimal

import math.big
import math
import strings
import strconv
import regex

const division_precision = 21

pub const zero = value_of(0)
pub const one = value_of(1)
pub const two = value_of(2)
pub const three = value_of(3)
pub const four = value_of(4)
pub const five = value_of(5)
pub const six = value_of(6)
pub const seven = value_of(7)
pub const eight = value_of(8)
pub const nine = value_of(9)
pub const ten = value_of(10)
pub const twenty = value_of(20)
pub const thirty = value_of(30)
pub const forty = value_of(40)
pub const fifty = value_of(50)
pub const sixty = value_of(60)
pub const seventy = value_of(70)
pub const eighty = value_of(80)
pub const ninety = value_of(90)
pub const one_hundred = value_of(100)

pub enum Round {
        round_up        = 1
        round_down
        round_half_up
        round_half_down
        round_ceil
        round_floor
        round_bank
        round_cash
        truncate
}

type ValueOfType = f32 | f64 | i32 | i64 | int | string | u32 | u64

pub struct Decimal {
        value big.Integer
        exp   int
}

// new creates a new Decimal with the given value and exponent.
pub fn new(value i64, exp int) Decimal {
        return Decimal{
                value: big.integer_from_i64(value)
                exp: exp
        }
}

// value_of creates a new Decimal from the given value.
pub fn value_of(value ValueOfType) Decimal {
        if value is int || value is i32 {
                return from_int(value as int)
        } else if value is u32 {
                return from_u32(value)
        } else if value is i64 {
                return from_i64(value)
        } else if value is u64 {
                return from_u64(value)
        } else if value is string {
                return from_string(value)
        }

        panic('can\'t convert ${typeof(value).name} type to decimal')
}

// from_string creates a new Decimal from the given string value.
pub fn from_string(value1 string) Decimal {
        mut int_string := ''
        mut exp := i64(0)
        mut value := value1

        e_index := value.index_any('Ee')

        if e_index != -1 {
                exp_int := strconv.parse_int(value[e_index + 1..], 10, 32) or {
                        panic("can't convert ${value} to decimal: exponent is not numeric")
                }

                value = value[..e_index]
                exp = exp_int
        }

        mut p_index := -1
        for i := 0; i < value.len; i++ {
                if value[i] == `.` {
                        if p_index > -1 {
                                panic('can\'t convert ${value} to decimal: too many .s"')
                        }
                        p_index = i
                }
        }

        if p_index == -1 {
                int_string = value
        } else {
                if p_index + 1 < value.len {
                        int_string = value.substr(0, p_index) + value.substr(p_index + 1, value.len)     
                } else {
                        int_string = value.substr(0, p_index)
                }

                if p_index + 1 < value.len {
                        int_string = value[..p_index] + value[p_index + 1..]
                } else {
                        int_string = value[..p_index]
                }
                exp_int := -(value[p_index + 1..]).len
                exp += i64(exp_int)
        }

        mut d_value := big.zero_int

        // strconv.ParseInt is faster than new(big.Int).SetString so this is just a shortcut for strings we know won't overflow
        if int_string.len <= 18 {
                parsed64 := strconv.parse_int(int_string, 10, 64) or {
                        panic("can't convert ${value} to decimal")
                }

                d_value = big.integer_from_i64(parsed64)
        } else {
                d_value = big.integer_from_radix(int_string, 10) or {
                        panic("can't convert ${value} to decimal")
                }
        }

        if exp < math.min_i32 || exp > math.max_i32 {
                panic("can't convert ${value1} to to decimal: fractional part too long")

                // NOTE(vadim): I doubt a string could realistically be this long
        }

        return Decimal{
                value: d_value
                exp: i32(exp)
        }
}

// NewFromFormattedString returns a new Decimal from a formatted string representation.
// The second argument - replRegexp, is a regular expression that is used to find characters that should be
// removed from given decimal string representation. All matched characters will be replaced with an empty string.
//
// Example:
//
//     r := regexp.MustCompile("[$,]")
//     d1, err := NewFromFormattedString("$5,125.99", r)
//
//     r2 := regexp.MustCompile("[_]")
//     d2, err := NewFromFormattedString("1_000_000", r2)
//
//     r3 := regexp.MustCompile("[USD\\s]")
//     d3, err := NewFromFormattedString("5000 USD", r3)
//
fn from_formatted_string(value string, mut re regex.RE) Decimal {
        parsed_value := re.replace(value, '')
        d := from_string(parsed_value)
        return d
}

// from_int creates a new Decimal from the given int value.
pub fn from_int(a int) Decimal {
        return Decimal{
                value: big.integer_from_i64(a)
                exp: 0
        }
}

// from_u32 creates a new Decimal from the given u32 value.
pub fn from_u32(a u32) Decimal {
        return Decimal{
                value: big.integer_from_u32(a)
                exp: 0
        }
}

// from_i64 creates a new Decimal from the given i64 value.
pub fn from_i64(a i64) Decimal {
        return Decimal{
                value: big.integer_from_i64(a)
                exp: 0
        }
}

// from_u64 creates a new Decimal from the given u64 value.
pub fn from_u64(a u64) Decimal {
        return Decimal{
                value: big.integer_from_u64(a)
                exp: 0
        }
}

// from_big_integer returns a new Decimal from a big.Int, value * 10 ^ exp
fn from_big_integer(value big.Integer, exp i32) Decimal {
        return Decimal{
                value: value
                exp: exp
        }
}

// from_f64 converts a f32 to Decimal.
pub fn from_f32(value f32) Decimal {
        if value == 0 {
                return new(0, 0)
        }
        if math.is_nan(value) || math.is_inf(value, 0) {
                panic('Cannot create a Decimal from ${value}')
        }

        return from_string(value.str())
}

// from_f64 converts a f64 to Decimal.
pub fn from_f64(value f64) Decimal {
        if value == 0 {
                return new(0, 0)
        }
        if math.is_nan(value) || math.is_inf(value, 0) {
                panic('Cannot create a Decimal from ${value}')
        }

        return from_string(value.str())
}

// int_part returns the integer component of the decimal.
pub fn (d Decimal) int_part() int {
        scaled := d.rescale(0)
        return scaled.value.int()
}

// rescale returns a rescaled version of the decimal. Returned
// decimal may be less precise if the given exponent is bigger
// than the initial exponent of the Decimal.
// NOTE: this will truncate, NOT round
//
// Example:
//
//      d := new(12345, -4)
//      d2 := d.rescale(-1)
//      d3 := d2.rescale(-4)
//      println(d)
//      println(d2)
//      println(d3)
//
// Output:
//
//      1.2345
//      1.2
//      1.2000
//
fn (d Decimal) rescale(exp int) Decimal {
        if d.exp == exp {
                return d
        }

        diff := u32(math.abs(exp - d.exp))
        mut value := d.value

        ten_int := big.integer_from_int(10)
        exp_scale := ten_int.pow(diff)

        if exp > d.exp {
                value /= exp_scale
        } else if exp < d.exp {
                value *= exp_scale
        }

        return Decimal{
                value: value
                exp: exp
        }
}

// rescale_pair rescales two decimals to common exponential value (minimal exp of both decimals)
fn rescale_pair(d1 Decimal, d2 Decimal) (Decimal, Decimal) {
        if d1.exp == d2.exp {
                return d1, d2
        }
        base_scale := math.min(d1.exp, d2.exp)
        if base_scale != d1.exp {
                return d1.rescale(base_scale), d2
        }
        return d1, d2.rescale(base_scale)
}

// with the fixed point.
// Trailing zeroes in the fractional part are trimmed.
//
// Example:
//
//     d := new(-12345, -3)
//     println(d)
//
// Output:
//
//     -12.345
//
pub fn (d Decimal) str() string {
        if d.exp >= 0 {
                return d.rescale(0).value.str()
        }
        abs := d.value.abs()
        str := abs.str()

        mut int_part := ''
        mut fractional_part := ''

        if str.len > -d.exp {
                int_part = str.substr(0, str.len + d.exp)
                fractional_part = str.substr(str.len + d.exp, str.len)
        } else {
                int_part = '0'
                num_zeroes := -d.exp - str.len
                fractional_part = strings.repeat(`0`, num_zeroes) + str
        }
        mut number := int_part
        if fractional_part.len > 0 {
                number += '.' + fractional_part
        }
        if d.value.signum < 0 {
                return '-' + number
        }
        return number
}

pub fn (decimal Decimal) + (addend Decimal) Decimal {
        return decimal.add(addend)
}

pub fn (decimal Decimal) add(addend Decimal) Decimal {
        rd, rd2 := rescale_pair(decimal, addend)
        result_value := rd.value + rd2.value
        return Decimal{
                value: result_value
                exp: rd.exp
        }
}

pub fn (decimal Decimal) add_scale(addend Decimal, scale i32, round Round) Decimal {
        return decimal.add(addend).round(scale, round)
}

pub fn (decimal Decimal) - (subtrahend Decimal) Decimal {
        return decimal.sub(subtrahend)
}

pub fn (decimal Decimal) sub(subtrahend Decimal) Decimal {
        rd, rd2 := rescale_pair(decimal, subtrahend)
        result_value := rd.value - rd2.value
        return Decimal{
                value: result_value
                exp: rd.exp
        }
}

pub fn (decimal Decimal) sub_scale(addend Decimal, scale i32, round Round) Decimal {
        return decimal.sub(addend).round(scale, round)
}

pub fn (decimal Decimal) * (multiplicand Decimal) Decimal {
        return decimal.mul(multiplicand)
}

pub fn (decimal Decimal) mul(multiplicand Decimal) Decimal {
        exp_i64 := i64(decimal.exp) + i64(multiplicand.exp)

        if exp_i64 > i64(math.max_i32) || exp_i64 < i64(math.min_i32) {
                panic('exponent ${exp_i64} overflows an int32')
        }

        result_value := decimal.value * multiplicand.value
        return Decimal{
                value: result_value
                exp: int(exp_i64)
        }
}

pub fn (decimal Decimal) mul_scale(multiplicand Decimal, scale i32, round Round) Decimal {
        return decimal.mul(multiplicand).round(scale, round)
}

pub fn (d Decimal) / (d2 Decimal) Decimal {
        return d.div(d2)
}

pub fn (d Decimal) div(d2 Decimal) Decimal {
        if d2.value.signum == 0 {
                panic('decimal division by 0')
        }
        scale := -vdecimal.division_precision
        e := i64(d.exp - d2.exp - scale)
        if e > math.max_i32 || e < math.min_i32 {
                panic('overflow in decimal QuoRem')
        }

        mut aa := big.Integer{}
        mut bb := big.Integer{}

        if e < 0 {
                aa = d.value
                bb = d2.value * big.integer_from_int(10).pow(u32(math.abs(e)))
        } else {
                aa = d.value * big.integer_from_int(10).pow(u32(math.abs(e)))
                bb = d2.value
        }

        result_value := aa / bb

        dv := Decimal{
                value: result_value
                exp: int(scale)
        }
        return dv.remove_trailing_zeros()
}

pub fn (decimal Decimal) div_scale(div2 Decimal, scale i32, round Round) Decimal {
        return decimal.div(div2).round(scale, round)
}

// cmp compares the numbers represented by d and d2 and returns:
//
//     -1 if d <  d2
//      0 if d == d2
//     +1 if d >  d2
//
pub fn (a Decimal) cmp(b Decimal) int {
        rd_a, rd_b := rescale_pair(a, b)
        if rd_a.value == rd_b.value {
                return 0
        } else if rd_a.value < rd_b.value {
                return -1
        } else {
                return 1
        }
}

// equal returns whether the numbers represented by d and d2 are equal.
pub fn (d Decimal) equal(d2 Decimal) bool {
        return d.cmp(d2) == 0
}

// greater_than (GT) returns true when d is greater than d2.
pub fn (d Decimal) greater_than(d2 Decimal) bool {
        return d.cmp(d2) == 1
}

// greater_than_or_equal (GTE) returns true when d is greater than or equal to d2.
pub fn (d Decimal) greater_than_or_equal(d2 Decimal) bool {
        cmp := d.cmp(d2)
        return cmp == 1 || cmp == 0
}

// less_than (LT) returns true when d is less than d2.
pub fn (d Decimal) less_than(d2 Decimal) bool {
        return d.cmp(d2) == -1
}

// less_than_or_equal (LTE) returns true when d is less than or equal to d2.
pub fn (d Decimal) less_than_or_equal(d2 Decimal) bool {
        cmp := d.cmp(d2)
        return cmp == -1 || cmp == 0
}

// sign returns:
//
//      -1 if d <  0
//       0 if d == 0
//      +1 if d >  0
//
pub fn (d Decimal) sign() int {
        return d.value.signum
}

// is_positive return
//
//      true if d > 0
//      false if d == 0
//      false if d < 0
pub fn (d Decimal) is_positive() bool {
        return d.sign() == 1
}

// is_negative return
//
//      true if d < 0
//      false if d == 0
//      false if d > 0
pub fn (d Decimal) is_negative() bool {
        return d.sign() == -1
}

// is_zero return
//
//      true if d == 0
//      false if d > 0
//      false if d < 0
pub fn (d Decimal) is_zero() bool {
        return d.sign() == 0
}

// exponent returns the exponent, or scale component of the decimal.
pub fn (d Decimal) exponent() int {
        return d.exp
}

// coefficient returns the coefficient of the decimal. It is scaled by 10^Exponent()
pub fn (d Decimal) coefficient() big.Integer {
        // we copy the coefficient so that mutating the result does not mutate the Decimal.
        return d.value
}

// abs calculates absolute value of any i32. Used for calculating absolute value of decimal's exponent.  
pub fn (d Decimal) abs() Decimal {
        return Decimal{
                value: d.value.abs()
                exp: d.exp
        }
}

// pow Calculates the power of the Decimal value.
pub fn (d Decimal) pow(exp int) Decimal {
        return Decimal{
                value: d.value.pow(u32(exp))
                exp: d.exp * exp
        }
}

// remove_trailing_zeros Removes trailing zeros from the decimal value.
pub fn (d Decimal) remove_trailing_zeros() Decimal {
        value_str := d.str()
        value_str.index('.') or { return Decimal{
                value: d.value
                exp: d.exp
        } }
        truncated_value := value_str.trim_right('0')
        return from_string(truncated_value)
}

// round rounds the decimal to places decimal places.
pub fn (d Decimal) round(places i32, round Round) Decimal {
        match round {
                .round_up {
                        return d.round_up(places)
                }
                .round_down {
                        return d.round_down(places)
                }
                .round_half_up {
                        return d.round_half_up(places)
                }
                .round_half_down {
                        return d.round_half_down(places)
                }
                .round_ceil {
                        return d.round_ceil(places)
                }
                .round_floor {
                        return d.round_floor(places)
                }
                .round_bank {
                        return d.round_bank(places)
                }
                .round_cash {
                        return d.round_cash(places)
                }
                .truncate {
                        return d.truncate(places)
                }
        }

        panic('error')
}

// round_half_up rounds the decimal to places decimal places.
// If places < 0, it will round the integer part to the nearest 10^(-places).
//
// Example:
//
//         value_of("5.45").round_half_up(1).str() // output: "5.5"
//         value_of(545).round_half_up(-1).str() // output: "550"
//
pub fn (d Decimal) round_half_up(places i32) Decimal {
        if d.exp == -places {
                return d
        }

        // truncate to places + 1
        ret := d.rescale(-places - 1)

        mut value := ret.value
        mut exp := ret.exp

        // add sign(d) * 0.5
        if ret.value.signum < 0 {
                value -= big.integer_from_int(5)
        } else {
                value += big.integer_from_int(5)
        }

        // floor for positive numbers, ceil for negative numbers
        mut q, m := value.div_mod(big.integer_from_int(10))

        exp = exp + 1
        if q.signum < 0 && !(m == big.zero_int) {
                q += big.one_int
        }

        return Decimal{
                value: q
                exp: exp
        }
}

// round_half_down rounds the decimal to places decimal places.
// If places < 0, it will round the integer part to the nearest 10^(-places).
//
// Example:
//
//         value_of("5.46").round_half_up(1).str() // output: "5.5"
//         value_of("5.45").round_half_up(1).str() // output: "5.4"
//
pub fn (d Decimal) round_half_down(places i32) Decimal {
        if d.exp == -places {
                return d
        }

        // truncate to places + 1
        ret := d.rescale(-places - 1)

        mut value := ret.value
        mut exp := ret.exp

        // add sign(d) * 0.5
        if ret.value.signum < 0 {
                value -= big.integer_from_int(4)
        } else {
                value += big.integer_from_int(4)
        }

        // floor for positive numbers, ceil for negative numbers
        mut q, m := value.div_mod(big.integer_from_int(10))

        exp = exp + 1
        if q.signum < 0 && !(m == big.zero_int) {
                q += big.one_int
        }

        return Decimal{
                value: q
                exp: exp
        }
}

// round_ceil rounds the decimal towards +infinity.
//
// Example:
//
//     value_of(545).round_ceil(-2).str()   // output: "600"
//     value_of(500).round_ceil(-2).str()   // output: "500"
//     value_of("1.1001").round_ceil(2).str() // output: "1.11"
//     value_of("-1.454").round_ceil(1).str() // output: "-1.5"
//
pub fn (d Decimal) round_ceil(places i32) Decimal {
        if d.exp >= -places {
                return d
        }

        rescaled := d.rescale(-places)
        if d == rescaled {
                return d
        }

        mut value := rescaled.value

        if d.value.signum > 0 {
                value += big.one_int
        }

        return Decimal{
                value: value
                exp: rescaled.exp
        }
}

// round_floor rounds the decimal towards -infinity.
//
// Example:
//
//     value_of(545).round_floor(-2).str()   // output: "500"
//     value_of(-500).round_floor(-2).str()   // output: "-500"
//     value_of("1.1001").round_floor(2).str() // output: "1.1"
//     value_of("-1.454").round_floor(1).str() // output: "-1.4"
//
pub fn (d Decimal) round_floor(places i32) Decimal {
        if d.exp >= -places {
                return d
        }

        rescaled := d.rescale(-places)
        if d == rescaled {
                return d
        }

        mut value := rescaled.value

        if d.value.signum < 0 {
                value -= big.one_int
        }

        return Decimal{
                value: value
                exp: rescaled.exp
        }
}

// round_up rounds the decimal away from zero.
//
// Example:
//
//     value_of(545).round_up(-2).str()   // output: "600"
//     value_of(500).round_up(-2).str()   // output: "500"
//     value_of("1.1001").round_up(2).str() // output: "1.11"
//     value_of("-1.454").round_up(1).str() // output: "-1.4"
//
pub fn (d Decimal) round_up(places i32) Decimal {
        if d.exp >= -places {
                return d
        }

        rescaled := d.rescale(-places)
        if d == rescaled {
                return d
        }

        mut value := rescaled.value

        if d.value.signum > 0 {
                value += big.one_int
        } else if d.value.signum < 0 {
                value -= big.one_int
        }

        return Decimal{
                value: value
                exp: rescaled.exp
        }
}

// round_down rounds the decimal towards zero.
//
// Example:
//
//     value_of(545).round_down(-2).String()   // output: "500"
//     value_of(-500).round_down(-2).String()   // output: "-500"
//     value_of("1.1001").round_down(2).String() // output: "1.1"
//     value_of("-1.454").round_down(1).String() // output: "-1.5"
//
pub fn (d Decimal) round_down(places i32) Decimal {
        if d.exp >= -places {
                return d
        }

        rescaled := d.rescale(-places)
        if d == rescaled {
                return d
        }

        return rescaled
}

// round_bank rounds the decimal to places decimal places.
// If the final digit to round is equidistant from the nearest two integers the
// rounded value is taken as the even number
//
// If places < 0, it will round the integer part to the nearest 10^(-places).
//
// Examples:
//
//         value_of("5.45").round_bank(1).String() // output: "5.4"
//         value_of(545).round_bank(-1).String() // output: "540"
//         value_of("5.46").round_bank(1).String() // output: "5.5"
//         value_of(546).round_bank(-1).String() // output: "550"
//         value_of("5.55").round_bank(1).String() // output: "5.6"
//         value_of(555).round_bank(-1).String() // output: "560"
//
pub fn (d Decimal) round_bank(places i32) Decimal {
        round := d.round_half_up(places)
        remainder := (d - round).abs()

        half := new(5, -places - 1)

        mut value := round.value

        if remainder.cmp(half) == 0 && round.value.get_bit(0) {
                if round.value.signum < 0 {
                        value = value + big.one_int
                } else {
                        value = value - big.one_int
                }
        }

        return Decimal{
                value: value
                exp: round.exp
        }
}

// round_cash aka Cash/Penny/öre rounding rounds decimal to a specific
// interval. The amount payable for a cash transaction is rounded to the nearest
// multiple of the minimum currency unit available. The following intervals are
// available: 5, 10, 25, 50 and 100; any other number throws a panic.
//          5:   5 cent rounding 3.43 => 3.45
//         10:  10 cent rounding 3.45 => 3.50 (5 gets rounded up)
//         25:  25 cent rounding 3.41 => 3.50
//         50:  50 cent rounding 3.75 => 4.00
//        100: 100 cent rounding 3.50 => 4.00
pub fn (d Decimal) round_cash(interval i32) Decimal {
        mut i_val := big.zero_int
        match interval {
                5 {
                        i_val = big.integer_from_int(20)
                }
                10 {
                        i_val = big.integer_from_int(10)
                }
                25 {
                        i_val = big.integer_from_int(4)
                }
                50 {
                        i_val = big.integer_from_int(2)
                }
                100 {
                        i_val = big.integer_from_int(1)
                }
                else {
                        panic('Decimal does not support this Cash rounding interval ${interval}. Supported: 5, 10, 25, 50, 100')
                }
        }

        d_val := value_of(i_val.str())
        return d.mul_scale(d_val, 0, Round.round_half_up).div_scale(d_val, 2, Round.truncate)
}

// floor returns the nearest integer value less than or equal to d.
pub fn (d Decimal) floor() Decimal {
        if d.exp >= 0 {
                return d
        }

        exp := big.integer_from_int(10).pow(u32(-d.exp))

        z, _ := d.value.div_mod(exp)
        return Decimal{
                value: z
                exp: 0
        }
}

// ceil returns the nearest integer value greater than or equal to d.
pub fn (d Decimal) ceil() Decimal {
        if d.exp >= 0 {
                return d
        }

        exp := big.integer_from_int(10).pow(u32(-d.exp))

        mut z, m := d.value.div_mod(exp)
        if !(m == big.zero_int) {
                z = z + big.one_int
        }
        return Decimal{
                value: z
                exp: 0
        }
}

// truncate truncates off digits from the number, without rounding.
//
// NOTE: precision is the last digit that will not be truncated (must be >= 0).
//
// Example:
//
//    value_of("123.456").truncate(2).String() // "123.45"
//
pub fn (d Decimal) truncate(precision i32) Decimal {
        if precision >= 0 && -precision > d.exp {
                return d.rescale(-precision)
        }
        return d
}