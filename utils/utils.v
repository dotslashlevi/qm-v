module utils

import math
import os
import strconv
import strings
import term

pub fn trim_time(time string) string {
	mut firstchar := strings.split[0]
	if firstchar == '00' {
		time = strings.split[1] + ':' + strings.split[2]
		firstchar = strings.split[0]
		if firstchar == '00' {
			time = strings.split[1]
			firstchar = time[0..1]
			if firstchar == '0' {
				time = time[1..]
			}
		}
	}
	return time
}

pub fn format_time(time_1 f64) string {
	mut hour := strconv.itoa(int(time_1 / 3600))
	mut minute := strconv.itoa(int(math.mod(time_1, 3600) / 60))
	mut second := strconv.format_float(math.mod(time_1, 60), `f`, 1, 64)
	if minute.len == 1 {
		minute = '0' + minute
	}
	if hour.len == 1 {
		hour = '0' + hour
	}
	if strings.split[0].len == 1 {
		second = '0' + second
	}
	return hour + ':' + minute + ':' + second + 's'
}

pub fn progress_bar(done f64, total f64, length int) string {
	mut bar := string('[')
	mut filled := f64(done / total * f64(length))
	if done >= 0.995 * total {
		filled = f64(length)
	}
	mut percent_done := int(int(filled))
	mut percent_left := int(length - percent_done)
	for i := 0; i < percent_done; i++ {
		bar += '\033[92m─'
	}
	if done == total {
		bar += '─\033[0m'
	} else {
		bar += '>\033[90m'
	}
	for i_1 := 0; i_1 < percent_left; i_1++ {
		bar += '─'
	}
	bar += '\033[0m]'
	return bar
}

pub fn progbar_size(length_1 int) int {
	mut terminal_width, _, _ := term.get_size(int(os.stdout.fd()))
	return terminal_width - 7 - length_1
}
