module main

import io
import io.util
import log
import math
import os
import strconv
import strings
import time
import qm-v.ffprobe
import qm-v.utils
import github.com.flopp.v-findfont
import github.com.spf13.pflag
import term

const (
  output=''
  inputs=[]string{}
  debug=false
  overwrite=false
  progbar_length=0
  image_passes=0
  loglevel=''
  update_speed=0.0
  no_video,no_audio=false,false
  replace_audio=''
  preset=0
  start,end,out_duration=0.0,0.0,0.0
  volume=0
  earrape=false
  out_scale=0.0
  video_br_div,audio_br_div=0,0
  stretch=''
  out_fps=0
  speed=0.0
  zoom=0.0
  fadein,fadeout=0.0,0.0
  stutter=0
  vignette=0.0
  corrupt=0
  fry=0
  interlace=false
  lagfun=false
  resample=false
  text,text_font,text_color='','',''
  textposx,textposy=0,0
  font_size=0.0
  unspecified_progbar_size=false
  str_fmt=Formats{}
)

struct Formats {
  mut:
  success string 
  success_hl string 
  warning string 
  warning_hl string 
  error string 
  error_hl string 
  info string 
  info_hl string 
  debug string 
  debug_hl string 
  working string 
  working_hl string 
  reset string 
}

fn init() {
  str_fmt=Formats{
    success:"\033[32m"  ,
    success_hl:"\033[92m"  ,
    warning:"\033[38;2;250;169;30m"  ,
    warning_hl:"\033[38;2;250;182;37m"  ,
    error:"\033[31m"  ,
    error_hl:"\033[91m"  ,
    info:"\033[94m"  ,
    info_hl:"\033[36m"  ,
    debug:"\033[36m"  ,
    debug_hl:"\033[96m"  ,
    working:"\033[94m"  ,
    working_hl:"\033[36m"  ,
    reset:"\033[0m"
  }
  
  pflag.command_line.sort_flags=false  
  pflag.string_slice_var_p(& inputs  ,"input" ,"i" ,["" ] ,"Specify the input file(s)" ,)
  pflag.string_var_p(& output  ,"output" ,"o" ,"" ,"Specify the output file" ,)
  pflag.bool_var_p(& debug  ,"debug" ,"d" ,false ,"Print out debug information" ,)
  pflag.bool_var_p(& overwrite  ,"overwrite" ,"y" ,false ,"Overwrite the output file if it exists instead of prompting for confirmation" ,)
  pflag.int_var(& progbar_length  ,"progress-bar" ,- 1  ,"Length of progress bar, defaults based on terminal width" ,)
  pflag.int_var(& image_passes  ,"loop" ,1 ,"Number of time to compress the input. ONLY USED FOR IMAGES." ,)
  pflag.string_var(& loglevel  ,"loglevel" ,"error" ,"Specify the log level for ffmpeg" ,)
  pflag.float64_var(& update_speed  ,"update-speed" ,0.0167 ,"Specify the speed at which stats will be updated" ,)
  pflag.bool_var(& no_video  ,"no-video" ,false ,"Produces an output with no video" ,)
  pflag.bool_var(& no_audio  ,"no-audio" ,false ,"Produces an output with no audio" ,)
  pflag.string_var(& replace_audio  ,"replace-audio" ,"" ,"Replace the audio with the specified file" ,)
  pflag.int_var_p(& preset  ,"preset" ,"p" ,4 ,"Specify the quality preset (1-7, higher = worse)" ,)
  pflag.float64_var(& start  ,"start" ,0 ,"Specify the start time of the output" ,)
  pflag.float64_var(& end  ,"end" ,- 1  ,"Specify the end time of the output, cannot be used when duration is specified" ,)
  pflag.float64_var(& out_duration  ,"duration" ,- 1  ,"Specify the duration of the output, cannot be used when end is specified" ,)
  pflag.int_var_p(& volume  ,"volume" ,"v" ,0 ,"Specify the amount to increase or decrease the volume by, in dB" ,)
  pflag.bool_var(& earrape  ,"earrape" ,false ,"Heavily and extremely distort the audio (aka earrape). BE WARNED: VOLUME WILL BE SUBSTANTIALLY INCREASED." ,)
  pflag.float64_var_p(& out_scale  ,"scale" ,"s" ,- 1  ,"Specify the output scale" ,)
  pflag.int_var(& video_br_div  ,"video-bitrate" ,- 1  ,"Specify the video bitrate divisor (higher = worse)" ,)
  pflag.int_var(& video_br_div  ,"vb" ,video_br_div ,"Shorthand for --video-bitrate" ,)
  pflag.int_var(& audio_br_div  ,"audio-bitrate" ,- 1  ,"Specify the audio bitrate divisor (higher = worse)" ,)
  pflag.int_var(& audio_br_div  ,"ab" ,audio_br_div ,"Shorthand for --audio-bitrate" ,)
  pflag.string_var(& stretch  ,"stretch" ,"1:1" ,"Modify the existing aspect ratio" ,)
  pflag.int_var(& out_fps  ,"fps" ,- 1  ,"Specify the output fps (lower = worse)" ,)
  pflag.float64_var(& speed  ,"speed" ,1.0 ,"Specify the video and audio speed" ,)
  pflag.float64_var_p(& zoom  ,"zoom" ,"z" ,1 ,"Specify the amount to zoom in or out" ,)
  pflag.float64_var(& fadein  ,"fade-in" ,0 ,"Fade in duration" ,)
  pflag.float64_var(& fadeout  ,"fade-out" ,0 ,"Fade out duration" ,)
  pflag.int_var(& stutter  ,"stutter" ,0 ,"Randomize the order of a frames (higher = more stutter)" ,)
  pflag.float64_var(& vignette  ,"vignette" ,0 ,"Specify the amount of vignette" ,)
  pflag.int_var(& corrupt  ,"corrupt" ,0 ,"Corrupt the output (1-10, higher = worse)" ,)
  pflag.int_var(& fry  ,"deep-fry" ,0 ,"Deep-fry the output (1-10, higher = worse)" ,)
  pflag.bool_var(& interlace  ,"interlace" ,false ,"Interlace the output" ,)
  pflag.bool_var(& lagfun  ,"lagfun" ,false ,"Force darker pixels to update slower" ,)
  pflag.bool_var(& resample  ,"resample" ,false ,"Blend frames together instead of dropping them" ,)
  pflag.string_var_p(& text  ,"text" ,"t" ,"" ,"Text to add (if empty, no text)" ,)
  pflag.string_var(& text_font  ,"text-font" ,"arial" ,"Text to add (if empty, no text)" ,)
  pflag.string_var(& text_color  ,"text-color" ,"white" ,"Text color" ,)
  pflag.int_var(& textposx  ,"text-pos-x" ,50 ,"horizontal position of text (0 is far left, 100 is far right)" ,)
  pflag.int_var(& textposy  ,"text-pos-y" ,90 ,"vertical position of text (0 is top, 100 is bottom)" ,)
  pflag.float64_var(& font_size  ,"font-size" ,12 ,"Font size (scales with output width)" ,)
  pflag.parse()
  
  if inputs[0 ]  ==  ""  {
    log.fatal("No input was specified" ,)
  }

  if start  <  0  {
    log.fatal("Start time cannot be negative" ,)
  }

  if start  >=  end   &&  end  !=  - 1    {
    log.fatal("Start time cannot be greater than or equal to end time" ,)
  }

  if out_duration  !=  - 1    &&  end  !=  - 1    {
    log.fatal("Cannot specify both duration and end time" ,)
  }

  if progbar_length  ==  - 1   {
    unspecified_progbar_size=true
  } else {
  unspecified_progbar_size=false
  }
}

pub fn stream(input_1 string, stream_1 string) (bool, ) {mut args:=["-i" ,input_1 ,"-show_entries" ,"stream=index" ,"-select_streams" ,stream_1 ,"-of" ,"csv=p=0" ]  
mut cmd:=exec.command("ffprobe" ,... args  ,)  
mut out,err_1:=cmd.output()  

if err_1  !=  unsafe { nil }  {
  return false 
}
return out .str() .len  !=  0  
}

fn new_resolution(inWidth int, inHeight int) (int, int, ) {mut out_width:=0 
mut out_height:=0 
mut aspect:=stretch .split(":" ,)  
mut aspect_width,err_1:=strconv.atoi(aspect[0 ] ,)  

if err_1  !=  unsafe { nil }  {
  log.print(err_1 ,)
}
mut aspect_height,err_2:=strconv.atoi(aspect[1 ] ,)  

if err_2  !=  unsafe { nil }  {
  log.print(err_2 ,)
}

if out_scale  ==  - 1   {
  out_scale=1.0  /  f64(preset ,)   
}
out_width=int(math.round(f64(inWidth ,)  *  out_scale   *  f64(aspect_width ,)  ,)  /  2  ,)  *  2   
out_height=int(math.round(f64(inHeight ,)  *  out_scale   *  f64(aspect_height ,)  ,)  /  2  ,)  *  2   

return out_width ,out_height 
}

fn make_text_filter(outWidth int, inText string, font string, size f64, color string, xpos int, ypos int) (string, ) {mut font_path,err_1:=findfont.find(font  +  ".ttf"  ,)  

if err_1  !=  unsafe { nil }  {
  panic(err_1 ,)
}

mut err_2:=os.mkdir_all("temp" ,os.mode_perm ,)

if err_2  !=  unsafe { nil }  {
  log.fatal(err_2 ,)
}

mut input_2,err_3:=ioutil.read_file(font_path ,)

if err_3  !=  unsafe { nil }  {
  log.print(err_3 ,)
}

err_3=ioutil.write_file("temp/font.ttf" ,input_2 ,0644 ,)

if err_3  !=  unsafe { nil }  {
  log.fatal(str_fmt.error  +  "Fatal Error: unable to create temp/font.ttf"   +  str_fmt.reset  ,)
}
mut filter_1:=",drawtext=fontfile='temp/font.ttf':text='"  +  inText   +  "':fontcolor="   +  color   +  ":borderw=("   +  strconv.format_float(size  *  f64(outWidth  /  100  ,)  ,`f` ,- 1  ,64 ,)   +  "/12):fontsize="   +  strconv.format_float(size  *  f64(outWidth  /  100  ,)  ,`f` ,- 1  ,64 ,)   +  ":x=(w-(tw))*("   +  strconv.itoa(xpos ,)   +  "/100):y=(h-(th))*("   +  strconv.itoa(ypos ,)   +  "/100)"   
if debug {
  log.println("text is " ,inText ,)
  log.println("fontpath: " ,font_path ,)
  log.println(filter_1 ,)
}
return filter_1 
}

fn get_eta(startingTime time.Time, current f64, total f64) (f64, ) {return time.since.seconds()  *  (total  -  current  )   /  current  
}

fn image_munch(input_1 string, inputData ffprobe.MediaData, inNum int, totalNum int) {if debug {
  log.print("resolution is " ,inputData.width ," by " ,inputData.height ,)
}

if out_scale  ==  - 1   {
  out_scale=1.0  /  f64(preset ,)   
}

if debug {
  log.print("Output scale is " ,out_scale ,)
}

mut output_width,output_height:=new_resolution(inputData.width ,inputData.height ,)  

mut filter:=strings.Builder{} 

filter.write_string("scale="  +  strconv.itoa(output_width ,)   +  ":"   +  strconv.itoa(output_height ,)   +  ",setsar=1:1"  ,)
if zoom  !=  1  {
  filter.write_string(",zoompan=d=1:zoom="  +  strconv.format_float(zoom ,`f` ,- 1  ,64 ,)   +  ":fps="   +  strconv.itoa(out_fps ,)   +  ":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"  ,)
  if debug {
  log.print("zoom amount is " ,zoom ,)
  }
}

if vignette  !=  0  {
  filter.write_string(",vignette=PI/(5/("  +  strconv.format_float(vignette ,`f` ,- 1  ,64 ,)   +  "/2))"  ,)

if debug {
  log.print("vignette amount is " ,vignette ," or PI/(5/("  +  strconv.format_float(vignette ,`f` ,- 1  ,64 ,)   +  "/2))"  ,)
}
}
if text  !=  ""  {
  filter.write_string(make_text_filter(output_width ,text ,text_font ,font_size ,text_color ,textposx ,textposy ,) ,)
}
if fry  !=  0  {
  filter.write_string(","  +  "eq=saturation="   +  strconv.format_float(f64(fry ,)  *  0.15   +  0.85  ,`f` ,- 1  ,64 ,)   +  ":contrast="   +  strconv.itoa(fry ,)   +  ",unsharp=5:5:1.25:5:5:"   +  strconv.format_float(f64(fry ,)  /  6.66  ,`f` ,- 1  ,64 ,)   +  ",noise=alls="   +  strconv.itoa(fry  *  5  ,)   +  ":allf=t"  ,)
if debug {
  log.print("fry is " ,","  +  "eq=saturation="   +  strconv.format_float(f64(fry ,)  *  0.15   +  0.85  ,`f` ,- 1  ,64 ,)   +  ":contrast="   +  strconv.itoa(fry ,)   +  ",unsharp=5:5:1.25:5:5:"   +  strconv.format_float(f64(fry ,)  /  6.66  ,`f` ,- 1  ,64 ,)   +  ",noise=alls="   +  strconv.itoa(fry  *  5  ,)   +  ":allf=t"  ,)
}
}
mut args:=["-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,input_1 ,"-c:v" ,"mjpeg" ,"-q:v" ,"31" ,"-frames:v" ,"1" ]  
if filter.string() .len  !=  0  {
  args <<["-filter_complex" ,filter.string() ]   
}
args <<output   
if debug {
  log.print(args ,)
}
mut encoding_file_out_of:='' 
if totalNum  !=  1  {
  encoding_file_out_of="["  +  strconv.itoa(inNum ,)   +  "/"   +  strconv.itoa(totalNum ,)   +  "] "   
}
println('${str_fmt.working}${encoding_file_out_of}Encoding ${str_fmt.working_hl}${filepath.base(input_1 ,) }${str_fmt.working}to${str_fmt.working_hl}${filepath.base(output ,) }${str_fmt.reset}' ,)
mut cmd:=exec.command("ffmpeg" ,... args  ,)  
cmd.start()
cmd.wait()
mut new_output:='' 
mut start_time_1:=time.now()  
mut eta:=0.0  

if image_passes  >  1  {
  mut err_1:=os.mkdir_all("temp" ,os.mode_perm ,) 
  if err_1  !=  unsafe { nil }  {
  log.fatal(err_1 ,)
}
new_output="temp/loop1.jpg"  
cmd=exec.command("ffmpeg" ,"-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,output ,"-c:v" ,"mjpeg" ,"-q:v" ,"31" ,"-frames:v" ,"1" ,new_output ,)  
cmd.start()
cmd.wait()
eta=get_eta(start_time_1 ,1 ,1 ,)  
if unspecified_progbar_size {
  progbar_length=utils.progbar_size(" "  +  (strconv.format_float((1  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,)  +  "%"   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)  )  .len ,)  
}

if progbar_length  >  0  {
  print(utils.progress_bar(1 ,f64(image_passes ,) ,progbar_length ,) ,)
  } else {
  print("\033[0J" ,)
}

println('  ${strconv.format_float((1  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,) }% ETA: ${utils.trim_time(utils.format_time(eta ,) ,) }\033[0J' ,)
if debug {
  log.print("libwebp:" ,)
  log.print("compression level: "  +  strconv.itoa(int(f64(1  /  f64(preset ,)  ,)  *  7.0  ,)  -  1  ,)  ,)
  log.print("quality: "  +  strconv.itoa(((preset )  *  12  )  +  16  ,)  ,)
  log.print("libx264:" ,)
  log.print("crf: "  +  strconv.itoa(int(f64(preset ,)  *  (51.0  /  7.0  )  ,) ,)  ,)
  log.print("mjpeg:" ,)
  log.print("q:v: "  +  strconv.itoa(int(f64(preset ,)  *  3.0  ,)  +  10  ,)  ,)
}
mut old_output:='' 
for i_1:=2  ;i_1  <  image_passes  -  1   ;i_1++ {
old_output=new_output  
new_output="temp/loop"  +  strconv.itoa(i_1 ,)   +  ".png"   
cmd=exec.command("ffmpeg" ,"-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,old_output ,"-c:v" ,"libwebp" ,"-compression_level" ,strconv.itoa(int(f64(1  /  f64(preset ,)  ,)  *  7.0  ,)  -  1  ,) ,"-quality" ,strconv.itoa(((preset )  *  12  )  +  16  ,) ,"-frames:v" ,"1" ,new_output ,)  
cmd.start()
cmd.wait()
os.remove(old_output ,)
eta=get_eta(start_time_1 ,f64(i_1 ,) ,f64(image_passes ,) ,)  

if unspecified_progbar_size {
  progbar_length=utils.progbar_size(" "  +  (strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,)  +  "%"   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)  )  .len ,)  
}

if progbar_length  >  0  {
  print('\033[1A ${utils.progress_bar(f64(i_1 ,) ,f64(image_passes ,) ,progbar_length ,) }' ,)
  } else {
  print("\033[1A\033[0J" ,)
}
println('  ${strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,) }% ETA: ${utils.trim_time(utils.format_time(eta ,) ,) }\033[0J' ,)
i_1++
old_output=new_output  
new_output="temp/loop"  +  strconv.itoa(i_1 ,)   +  ".png"   
cmd=exec.command("ffmpeg" ,"-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,old_output ,"-c:v" ,"libx264" ,"-crf" ,strconv.itoa(int(f64(preset ,)  *  (51.0  /  7.0  )  ,) ,) ,"-frames:v" ,"1" ,new_output ,)  
cmd.start()
cmd.wait()
os.remove(old_output ,)
eta=get_eta(start_time_1 ,f64(i_1 ,) ,f64(image_passes ,) ,)  

if unspecified_progbar_size {
  progbar_length=utils.progbar_size(" "  +  (strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,)  +  "%"   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)  )  .len ,)  
}

if progbar_length  >  0  {
  print('\033[1A ${utils.progress_bar(f64(i_1 ,) ,f64(image_passes ,) ,progbar_length ,) }' ,)
  } else {
  print("\033[1A\033[0J" ,)
}
println('  ${strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,) }% ETA: ${utils.trim_time(utils.format_time(eta ,) ,) }\033[0J' ,)
i_1++
old_output=new_output  
new_output="temp/loop"  +  strconv.itoa(i_1 ,)   +  ".jpg"   
cmd=exec.command("ffmpeg" ,"-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,old_output ,"-c:v" ,"mjpeg" ,"-q:v" ,strconv.itoa(int(f64(preset ,)  *  3.0  ,)  +  10  ,) ,"-frames:v" ,"1" ,new_output ,)  
cmd.start()
cmd.wait()
os.remove(old_output ,)
eta=get_eta(start_time_1 ,f64(i_1 ,) ,f64(image_passes ,) ,)  

if unspecified_progbar_size {
  progbar_length=utils.progbar_size(" "  +  (strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,)  +  "%"   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)  )  .len ,)  
}

if progbar_length  >  0  {
  print('\033[1A ${utils.progress_bar(f64(i_1 ,) ,f64(image_passes ,) ,progbar_length ,) }' ,)
  } else {
  print("\033[1A\033[0J" ,)
  }
  println('  ${strconv.format_float((f64(i_1 ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,) }% ETA: ${utils.trim_time(utils.format_time(eta ,) ,) }\033[0J' ,)
}

old_output=new_output  
cmd=exec.command("ffmpeg" ,"-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ,"-i" ,old_output ,"-c:v" ,"mjpeg" ,"-q:v" ,"31" ,"-frames:v" ,"1" ,output ,)  
cmd.start()
cmd.wait()
os.remove(old_output ,)
eta=get_eta(start_time_1 ,f64(image_passes ,) ,f64(image_passes ,) ,)
  
if unspecified_progbar_size {
  progbar_length=utils.progbar_size(" "  +  (strconv.format_float((f64(image_passes ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,)  +  "%"   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)  )  .len ,)  
}

if progbar_length  >  0  {
  print('\033[1A ${utils.progress_bar(f64(image_passes ,) ,f64(image_passes ,) ,progbar_length ,) }' ,)
  } else {
  print("\033[1A\033[0J" ,)
}

println('  ${strconv.format_float((f64(image_passes ,)  *  100   /  f64(image_passes ,)  ) ,`f` ,1 ,64 ,) }% ETA: ${utils.trim_time(utils.format_time(eta ,) ,) }\033[0J' ,)
}
}

fn video_munch(input_1 string, inputData ffprobe.MediaData, inNum int, totalNum int, renderVideo bool, renderAudio bool) {if ! renderVideo  {
inputData.width=1  
inputData.height=1  
inputData.framerate=1.0  
}
if debug {
  log.print("resolution is " ,inputData.width ," by " ,inputData.height ,)
}

if out_fps  ==  - 1   {
  out_fps=24  -  (3  *  preset  )   
}

if debug {
  log.print("Output FPS is " ,out_fps ,)
}

mut fps_filter:=string("fps="  +  strconv.itoa(out_fps ,)  ) 
mut tmix_frames:=int(0 ) 
if resample {
  if out_fps  <=  int(inputData.framerate ,)  {
  tmix_frames=int(inputData.framerate ,)  /  out_fps   
  fps_filter="tmix=frames="  +  strconv.itoa(tmix_frames ,)   +  ":weights=1,fps="   +  strconv.itoa(out_fps ,)   

if debug {
  log.print("resampling with tmix, tmix frames " ,tmix_frames ," and output fps is "  +  strconv.itoa(out_fps ,)  ,)
  }
  } else {
  log.fatal("Cannot resample from a lower framerate to a higher framerate (output fps exceeds input fps)" ,)
}
}

if out_scale  ==  - 1   {
  out_scale=1.0  /  f64(preset ,)   
}

if debug {
  log.print("Output scale is " ,out_scale ,)
}

mut output_width,output_height:=new_resolution(inputData.width ,inputData.height ,)  
mut bitrate:=0 
if video_br_div  !=  - 1   {
  bitrate=output_height  *  output_width   *  int(math.sqrt(f64(out_fps ,) ,) ,)   /  video_br_div   
  } else {
  bitrate=output_height  *  output_width   *  int(math.sqrt(f64(out_fps ,) ,) ,)   /  preset   
}
mut audio_bitrate:=0 
if audio_br_div  !=  - 1   {
  audio_bitrate=80000  /  audio_br_div   
  } else {
  audio_bitrate=80000  /  preset   
}

if debug {
  log.print("bitrate is " ,bitrate ," which i got by doing " ,output_height ,"*" ,output_width ,"*" ,int(math.sqrt(f64(out_fps ,) ,) ,) ,"/" ,preset ,)
}
mut filter:=strings.Builder{} 
if renderVideo {
  if speed  !=  1  {
    filter.write_string("setpts=(1/"  +  strconv.format_float(speed ,`f` ,- 1  ,64 ,)   +  ")*PTS,"  ,)
  if debug {
    log.print("speed is " ,speed ,)
  }
}
filter.write_string(fps_filter  +  ",scale="   +  strconv.itoa(output_width ,)   +  ":"   +  strconv.itoa(output_height ,)   +  ",setsar=1:1"  ,)
if fadein  !=  0  {
  filter.write_string(",fade=t=in:d="  +  strconv.format_float(fadein ,`f` ,- 1  ,64 ,)  ,)
if debug {
  log.print("fade in is " ,fadein ,)
}
}

if fadeout  !=  0  {
  filter.write_string(",fade=t=out:d="  +  strconv.format_float(fadeout ,`f` ,- 1  ,64 ,)   +  ":st="   +  strconv.format_float((inputData.duration  -  fadeout  ) ,`f` ,- 1  ,64 ,)  ,)
  if debug {
  log.print("fade out duration is " ,fadeout ," start time is " ,(inputData.duration  -  fadeout  ) ,)
  }
}
if zoom  !=  1  {
  filter.write_string(",zoompan=d=1:zoom="  +  strconv.format_float(zoom ,`f` ,- 1  ,64 ,)   +  ":fps="   +  strconv.itoa(out_fps ,)   +  ":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"  ,)
  if debug {
  log.print("zoom amount is " ,zoom ,)
}

}
if vignette  !=  0  {
  filter.write_string(",vignette=PI/(5/("  +  strconv.format_float(vignette ,`f` ,- 1  ,64 ,)   +  "/2))"  ,)
  if debug {
  log.print("vignette amount is " ,vignette ," or PI/(5/("  +  strconv.format_float(vignette ,`f` ,- 1  ,64 ,)   +  "/2))"  ,)
}
}

if text  !=  ""  {
  filter.write_string(make_text_filter(output_width ,text ,text_font ,font_size ,text_color ,textposx ,textposy ,) ,)
}

if interlace {
  filter.write_string(",interlace" ,)
}

if lagfun {
  filter.write_string(",lagfun" ,)
}

if stutter  !=  0  {
  filter.write_string(",random=frames="  +  strconv.itoa(stutter ,)  ,)
  if debug {
  log.print("stutter is " ,stutter ,)
}

}
if fry  !=  0  {
  filter.write_string(","  +  "eq=saturation="   +  strconv.format_float(f64(fry ,)  *  0.15   +  0.85  ,`f` ,- 1  ,64 ,)   +  ":contrast="   +  strconv.itoa(fry ,)   +  ",unsharp=5:5:1.25:5:5:"   +  strconv.format_float(f64(fry ,)  /  6.66  ,`f` ,- 1  ,64 ,)   +  ",noise=alls="   +  strconv.itoa(fry  *  5  ,)   +  ":allf=t"  ,)
  if debug {
  log.print("fry is " ,","  +  "eq=saturation="   +  strconv.format_float(f64(fry ,)  *  0.15   +  0.85  ,`f` ,- 1  ,64 ,)   +  ":contrast="   +  strconv.itoa(fry ,)   +  ",unsharp=5:5:1.25:5:5:"   +  strconv.format_float(f64(fry ,)  /  6.66  ,`f` ,- 1  ,64 ,)   +  ",noise=alls="   +  strconv.itoa(fry  *  5  ,)   +  ":allf=t"  ,)
  }
  }
  } else {
  log.print("no video, ignoring all video filters" ,)
}
mut real_output_duration:=0.0 
if out_duration  >=  inputData.duration   ||  out_duration  ==  - 1    {
  real_output_duration=(inputData.duration  -  start  )  /  speed   
  } else {
  real_output_duration=out_duration  /  speed   
}
if renderAudio {
  if earrape {
    filter.write_string(";aeval=sgn(val(5)):c=same" ,)
      if debug {
        log.print("earrape is true" ,)
}
}
if volume  !=  0  {
if earrape {
  filter.write_string(",volume="  +  strconv.itoa(volume ,)   +  "dB"  ,)
  } else {
  filter.write_string(";volume="  +  strconv.itoa(volume ,)   +  "dB"  ,)
}
if debug {
  log.print("volume is " ,volume ,)
}
}
if speed  !=  1  {
if replace_audio  !=  ""  {
filter.write_string(";[1]atempo="  +  strconv.format_float(speed ,`f` ,- 1  ,64 ,)  ,)
} else {
filter.write_string(";[0]atempo="  +  strconv.format_float(speed ,`f` ,- 1  ,64 ,)  ,)
}
if debug {
log.print("audio speed is " ,speed ,)
}
}
}else {
log.print("no audio, ignoring all audio filters" ,)
}
mut corrupt_amount:=0 
mut corrupt_filter:='' 
if corrupt  !=  0  {
corrupt_amount=int(f64(output_height  *  output_width  ,)  /  f64(bitrate ,)   *  100000.0   /  f64(corrupt  *  3  ,)  ,)  
corrupt_filter="noise="  +  strconv.itoa(corrupt_amount ,)   
if debug {
log.print("corrupt amount is" ,corrupt_amount ,)
log.print("(" ,output_height ," * " ,output_width ,")" ," / 2073600 * 1000000" ," / " ,"(" ,corrupt ,"* 10)" ,)
log.print("corrupt filter is -bsf " ,corrupt_filter ,)
}
}
mut args:=["-y" ,"-loglevel" ,loglevel ,"-hide_banner" ,"-progress" ,"-" ,"-stats_period" ,strconv.format_float(update_speed ,`f` ,- 1  ,64 ,) ]  
if start  !=  0  {
args <<["-ss" ,strconv.format_float(start ,`f` ,- 1  ,64 ,) ]   
}
if end  !=  - 1   {
out_duration=end  -  start   
}
if out_duration  !=  - 1   {
args <<["-t" ,strconv.format_float(out_duration ,`f` ,- 1  ,64 ,) ]   
}
if ! renderVideo  {
args <<"-vn"   
if debug {
log.print("no video" ,)
}
}
if ! renderAudio  {
args <<"-an"   
if debug {
log.print("no audio" ,)
}
}
args <<["-i" ,input_1 ]   
if replace_audio  !=  ""  {
args <<["-i" ,replace_audio ]   
args <<["-map" ,"0:v:0" ]   
args <<["-map" ,"1:a:0" ]   
if debug {
log.print("replacing audio" ,)
}
}
if renderVideo {
args <<["-preset" ,"ultrafast" ,"-shortest" ,"-c:v" ,"libx264" ,"-b:v" ,strconv.itoa(int(bitrate ,) ,) ,"-c:a" ,"aac" ,"-b:a" ,strconv.itoa(int(audio_bitrate ,) ,) ]   
}else {
args <<["-shortest" ,"-b:v" ,strconv.itoa(int(bitrate ,) ,) ,"-c:a" ,"libmp3lame" ,"-b:a" ,strconv.itoa(int(audio_bitrate ,) ,) ]   
}
if filter.string() .len  !=  0  {
args <<["-filter_complex" ,filter.string() ]   
}
if corrupt  !=  0  {
args <<["-bsf" ,corrupt_filter ]   
}
args <<output   
if debug {
log.print(args ,)
}
mut encoding_file_out_of:='' 
if totalNum  !=  1  {
encoding_file_out_of="["  +  strconv.itoa(inNum ,)   +  "/"   +  strconv.itoa(totalNum ,)   +  "] "   
}
println('${str_fmt.working}${encoding_file_out_of}Encoding ${str_fmt.working_hl}${filepath.base(input_1 ,) }${str_fmt.working}to${str_fmt.working_hl}${filepath.base(output ,) }${str_fmt.reset}' ,)
mut cmd:=exec.command("ffmpeg" ,... args  ,)  
mut stdout,_:=cmd.stdout_pipe()  
mut stderr,_:=cmd.stderr_pipe()  
cmd.start()
mut scanner_text_accum:=" "  
mut scannerror_text_accum:=" "  
mut eta:=0.0  
mut current_frame:=0  
mut full_time:=""  
mut old_frame:=0  
mut avg_framerate:=" "  
mut last_sec_avg_framerate:=" "  
mut start_time_1:=time.now()  
mut change_start_time:=time.now()  
mut current_total_time:=0.0 
if unspecified_progbar_size {
progbar_length=utils.progbar_size(" "  +  strconv.format_float((current_total_time  *  100   /  real_output_duration  ) ,`f` ,1 ,64 ,)   +  "%"   +  " time: "   +  utils.trim_time(full_time ,)   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)   +  " fps: "   +  avg_framerate   +  " fp1s: "   +  last_sec_avg_framerate  .len ,)  
}
if debug {
log.print("progbarLength is" ,progbar_length ,)
}
println(utils.progress_bar(0.0 ,real_output_duration ,progbar_length ,) ,)
mut scanner:=bufio.new_scanner(stdout ,)  
mut scannerror:=bufio.new_scanner(stderr ,)  
scanner.split(bufio.scan_runes ,)
scannerror.split(bufio.scan_runes ,)
for scanner.scan() {
scanner_text_accum+=scanner.text()  
if scanner.text()  ==  "\r"   ||  scanner.text()  ==  "\n"   {
if scanner_text_accum .contains("time=" ,) {
full_time=strings.split[1 ]  
mut hour,_:=strconv.atoi(strings.split[0 ] ,)  
mut min,_:=strconv.atoi(strings.split[1 ] ,)  
mut sec,_:=strconv.atoi(strings.split[0 ] ,)  
mut milisec,_:=strconv.parse_float("."  +  strings.split[1 ]  ,64 ,)  
full_time=strings.split[0 ]  +  [1 .. ]   +  "s"   
eta=get_eta(start_time_1 ,current_total_time ,real_output_duration ,)  
if unspecified_progbar_size {
mut terminal_width:=0 
mut last_terminal_width:=terminal_width  
terminal_width,_,_=term.get_size(int(os.stdout.fd() ,) ,)  
mut last_prog_bar:=progbar_length  
progbar_length=utils.progbar_size(" "  +  strconv.format_float((current_total_time  *  100   /  real_output_duration  ) ,`f` ,1 ,64 ,)   +  "%"   +  " time: "   +  utils.trim_time(full_time ,)   +  " ETA: "   +  utils.trim_time(utils.format_time(eta ,) ,)   +  " fps: "   +  avg_framerate   +  " fp1s: "   +  last_sec_avg_framerate  .len ,)  
if (last_prog_bar  +  1   ==  progbar_length   ||  last_prog_bar  -  1   ==  progbar_length   )  &&  terminal_width  ==  last_terminal_width   {
progbar_length=last_prog_bar  
}
}
current_total_time=f64(hour  *  3600   +  min  *  60    +  sec  ,)  +  milisec   
if progbar_length  >  0  {
print('\033[1A ${utils.progress_bar(current_total_time ,real_output_duration ,progbar_length ,) }' ,)
}else {
print("\033[1A\033[0J" ,)
}
print('  ${strconv.format_float((current_total_time  *  100   /  real_output_duration  ) ,`f` ,1 ,64 ,) } %' ,)
}
if scanner_text_accum .contains("frame=" ,) {
current_frame,_=strconv.atoi(strings.split[1 ] ,)  
avg_framerate=strconv.format_float(f64(current_frame ,)  /  time.since.seconds()  ,`f` ,1 ,64 ,)  
if time.since.seconds()  >=  1  {
last_sec_avg_framerate=strconv.format_float(f64(current_frame  -  old_frame  ,)  /  time.since.seconds()  ,`f` ,1 ,64 ,)  
old_frame=current_frame  
change_start_time=time.now()  
}
}
if scanner_text_accum .contains("speed=" ,) {
print(' time:  ${utils.trim_time(full_time ,) }' ,)
print(' ETA:  ${utils.trim_time(utils.format_time(eta ,) ,) }' ,)
print(' fps:  ${avg_framerate}' ,)
print("\033[0J" ,)
print(' fp1s:  ${last_sec_avg_framerate}' ,)
print("\n" ,)
}
scanner_text_accum=""  
}
}
for scannerror.scan() {
scannerror_text_accum+=scannerror.text()  
}
cmd.wait()
if scannerror_text_accum .len  >  1  {
println('\n\n${str_fmt.error}Possible FFmpeg Error:${scannerror_text_accum}${str_fmt.reset}' ,)
}else {
if progbar_length  >  0  {
print('\033[1A\033[0J ${utils.progress_bar(real_output_duration ,real_output_duration ,progbar_length ,) }' ,)
}else {
print("\033[1A\033[0J" ,)
}
print(' 100.0%  time:  ${utils.trim_time(full_time ,) }  ETA:  ${utils.trim_time(utils.format_time(eta ,) ,) }  fps:  ${avg_framerate}  fp1s:  ${last_sec_avg_framerate} \n' ,)
}
}

fn main() {if debug {
log.println("throwing all flags out" ,)
log.println(inputs ,output ,debug ,progbar_length ,image_passes ,loglevel ,update_speed ,no_video ,no_audio ,preset ,start ,end ,out_duration ,volume ,out_scale ,video_br_div ,audio_br_div ,stretch ,out_fps ,speed ,zoom ,fadein ,fadeout ,stutter ,vignette ,corrupt ,interlace ,lagfun ,resample ,text ,text_font ,text_color ,textposx ,textposy ,font_size ,)
}
for i, input in  inputs  {
mut _,err:=os.stat(input ,)  
if err  !=  unsafe { nil }  {
if os.is_not_exist(err ,) {
log.println(str_fmt.error  +  "Error: input file"  ,str_fmt.error_hl  +  input   +  str_fmt.error  ,"does not exist"  +  str_fmt.reset  ,)
continue 
}else {
println('${str_fmt.warning}Warning: Input file${str_fmt.warning_hl}${input}${str_fmt.warning}might not be accessible.${str_fmt.reset}' ,)
}
}
if unspecified_progbar_size {
progbar_length=0  
}
if debug {
log.println("input: "  +  input  ,)
log.println("input #: "  +  strconv.itoa(i ,)  ,)
}
mut render_video:=! no_video   
mut render_audio:=! no_audio   
if ! no_video  {
render_video=stream(input ,"v:0" ,)  
}
if replace_audio .str() .len  ==  0  {
if ! no_audio  {
render_audio=stream(input ,"a:0" ,)  
}
}
mut input_data,_:=ffprobe.probe_data(input ,)  
mut is_image:=false  
mut out_ext:=".mp4"  
if render_audio  &&  ! render_video   {
out_ext=".mp3"  
}
if ! render_video   &&  ! render_audio   {
log.println(str_fmt.error  +  "Error: Cannot encode video without audio or video streams"   +  str_fmt.reset  ,)
continue 
}
if input_data.duration  <  1.0   &&  render_video  {
if ffprobe.frame_count(input ,)  ==  1  {
log.print("duration: " ,input_data.duration ,)
is_image=true  
out_ext=".jpg"  
}
}
if inputs .len  >  1  {
output=input .trim_suffix(filepath.ext(input ,) ,)  +  " (Quality Munched)"   +  out_ext   
}
if output  ==  ""  {
output=input .trim_suffix(filepath.ext(input ,) ,)  +  " (Quality Munched)"   +  out_ext   
if debug {
log.println("No output was specified, using input name plus (Quality Munched)" ,)
log.println("output: "  +  output  ,)
}
}else {
if ! output .contains(":" ,)  {
output=filepath.dir(input ,)  +  "/"   +  output   
}
}
mut _,out_exist_err:=os.stat(output ,)  
if out_exist_err  ==  unsafe { nil }  {
if debug {
log.print("output file already exists" ,)
}
mut confirm:='' 
if ! overwrite  {
println('${str_fmt.warning}Warning: The output file${str_fmt.warning_hl}${output}${str_fmt.warning}already exists! Overwrite? [Y/N]${str_fmt.reset}' ,)
NOT_YET_IMPLEMENTED
if confirm  !=  "Y"   &&  confirm  !=  "y"   {
log.println("Aborted by user - output file already exists" ,)
continue 
}
}
}
mut start_time:=time.now()  
if is_image {
if debug {
log.println("input is an image" ,)
}
image_munch(input ,input_data ,i  +  1  ,inputs .len ,)
}else {
if start  >=  input_data.duration  {
log.fatal("Start time cannot be greater than or equal to input duration" ,)
}
video_munch(input ,input_data ,i  +  1  ,inputs .len ,render_video ,render_audio ,)
}
mut _,out_err:=os.stat(output ,)  
if out_err  !=  unsafe { nil }  {
if os.is_not_exist(out_err ,) {
log.fatal(str_fmt.error  +  "Fatal Error: something went wrong when making the output file!"   +  str_fmt.reset  ,)
log.fatal(str_fmt.error  +  "Fatal Error: something went wrong when making the output file!"   +  str_fmt.reset  ,)
}else {
log.fatal(err ,)
}
}else {
println('${str_fmt.success}Finished encoding${str_fmt.success_hl}${output}${str_fmt.success}in ${utils.trim_time(utils.format_time(time.since.seconds() ,) ,) }${str_fmt.reset}' ,)
}
}
}
