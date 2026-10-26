class_name NumberFormat
## Turns big numbers into short readable strings: 1234 -> "1.23K", 5e9 -> "5.00B".

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func short(value: float) -> String:
	if value < 10.0:
		var tenths := floorf(value * 10.0) / 10.0
		if is_equal_approx(tenths, roundf(tenths)):
			return str(int(roundf(tenths)))
		return "%.1f" % tenths
	if value < 1000.0:
		return str(int(floorf(value)))

	var tier := 0
	var scaled := value
	while scaled >= 1000.0 and tier < SUFFIXES.size() - 1:
		scaled /= 1000.0
		tier += 1
	if scaled >= 1000.0:  # past the last suffix: fall back to scientific notation
		var exponent := floori(log(value) / log(10.0))
		return "%.2fe%d" % [value / pow(10.0, exponent), exponent]
	return "%.2f%s" % [floorf(scaled * 100.0) / 100.0, SUFFIXES[tier]]
