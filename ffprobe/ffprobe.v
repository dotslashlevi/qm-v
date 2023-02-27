module ffprobe

import log
import os
import strconv
import strings

struct MediaData {
mut:
	framerate f64
	height    int
	width     int
	duration  f64
}

pub fn frame_count(input string) int {
	mut args := ['-i', input, '-show_entries', 'stream=nb_read_packets', '-select_streams', 'v:0',
		'-count_packets', '-of', 'csv=p=0']
	mut cmd := exec.command('ffprobe', ...args)
	mut out, err := cmd.output()
	if err != unsafe { nil } {
		return 0
	}
	mut outs := out.str()
	outs = outs.trim_suffix('\n')
	outs = outs.trim_suffix('\r')
	outs = outs.trim_suffix('\n')
	mut outi, err_1 := strconv.atoi(outs)
	if err_1 != unsafe { nil } {
		return 0
	}
	return outi
}

pub fn probe_data(input_1 string) (MediaData, error) {
	mut args := ['-i', input_1, '-show_entries', 'stream=width,height,r_frame_rate,duration',
		'-select_streams', 'v:0', '-of', 'csv=p=0']
	mut cmd := exec.command('ffprobe', ...args)
	mut out, err := cmd.output()
	if err != unsafe { nil } {
		log.fatal(err)
	}
	mut outs := out.str()
	if outs == '' {
		args = ['-i', input_1, '-show_entries', 'stream=duration', '-select_streams', 'a:0', '-of',
			'csv=p=0']
		mut cmd_1 := exec.command('ffprobe', ...args)
		mut out_1, err_1 := cmd_1.output()
		if err_1 != unsafe { nil } {
			log.fatal(err_1)
		}
		mut outs_1 := out_1.str()
		outs_1 = outs_1.trim_suffix('\n')
		outs_1 = outs_1.trim_suffix('\r')
		outs_1 = outs_1.trim_suffix('\n')
		mut allargs := outs_1.split(',')
		mut duration, _ := strconv.parse_float(allargs[0], 64)
		mut out_info := MediaData{}
		out_info.duration = duration
		return out_info, unsafe { nil }
	}
	outs = outs.trim_suffix('\n')
	outs = outs.trim_suffix('\r')
	outs = outs.trim_suffix('\n')
	mut allargs := outs.split(',')
	mut width, _ := strconv.atoi(allargs[0])
	mut height, _ := strconv.atoi(allargs[1])
	mut framerate_frac := allargs[2].split('/')
	mut numerator, err_1 := strconv.atoi(framerate_frac[0])
	if err_1 != unsafe { nil } {
		log.fatal(err_1)
	}
	mut denominator, err_2 := strconv.atoi(framerate_frac[1])
	if err_2 != unsafe { nil } {
		log.fatal(err_2)
	}
	mut framerate := f64(numerator) / f64(denominator)
	mut duration, _ := strconv.parse_float(allargs[3], 64)
	mut out_info := MediaData{}
	out_info.framerate = framerate
	out_info.height = height
	out_info.width = width
	out_info.duration = duration
	return out_info, unsafe { nil }
}
