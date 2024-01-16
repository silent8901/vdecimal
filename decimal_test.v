module vdecimal

import regex

fn test_int() {
	// perfectly convertable
	i := 123
	mut d := from_int(i)
	assert i.str() == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert d.str() == "123.9"
}


fn test_new() {
	// perfectly convertable
	i := 123
	mut d := from_int(i)
	assert i.str() == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert d.str() == "123.9"
}

fn test_u32() {
	i := u32(123)
	mut d := from_u32(i)
	assert i.str() == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert d.str() == "123.9"
}


fn test_i64() {
	i := i64(123)
	mut d := from_i64(i)
	assert i.str() == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert d.str() == "123.9"
}


fn test_u64() {
	i := u64(123)
	mut d := from_i64(i)
	assert i.str() == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert d.str() == "123.9"
}


fn test_string() {
	i := "2.41E-3"
	mut d := from_string(i)
	println(d)

        mut r := regex.regex_opt("[$,]") or { panic(err) }
        d1 := from_formatted_string(r"$5,125.99", mut r)
 assert d1.str() == "5125.99"
      

        mut r2 := regex.regex_opt("[_]")or { panic(err) }
        d2 := from_formatted_string("1_000_000", mut r2)
 assert d2.str() == "1000000"


        mut r3 := regex.regex_opt("[USD\\s]")or { panic(err) }
        d3 := from_formatted_string("5000 USD", mut r3)
        assert d3.str() == "5000"
}


fn test_value_of() {
	i := "123.9"
	mut d := value_of(i)
	assert i == d.str()
	// int_part should truncate the fractional part
	d = new(1239, -1)
	assert i == d.str()
}


fn test_add() {
	d1:= from_string("2.356")
        d2:= from_string("2.128")
	assert "4.484" == d1.add(d2).str()
	
	assert "4.484" == (d1 + d2).str()
}


fn test_sub() {
	d1:= from_string("2.356")
        d2:= from_string("2.128")
	assert "0.228" == d1.sub(d2).str()
	
	assert "0.228" == (d1 - d2).str()
}


fn test_mul() {
	d1:= from_string("2.356")
        d2:= from_string("2.128")
	assert "5.013568" == d1.mul(d2).str()
	
	assert "5.013568" == (d1 * d2).str()
}


fn test_div() {
	d1:= from_string("2.356")
        d2:= from_string("0.2")
	assert "11.78" == d1.div(d2).str()
	
	assert "11.78" == (d1 / d2).str()
}