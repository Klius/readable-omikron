extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var omikron_dir_path
var bad_fnt = ["sneak.fnt","menusave.fnt","menuintr.fnt","parchemi.fnt"]
var good_fnt = "journal.fnt"
const JOURNAL_MD5 = "68e730bf3e67b36dca7892a8dc4aa26c"
const CHUNK_SIZE = 1024


func hash_file(path):
	var ctx = HashingContext.new()
	var file = File.new()
	# Start a MD5 context.
	ctx.start(HashingContext.HASH_MD5)
	# Check that file exists.
	if not file.file_exists(path):
		return
	# Open the file to hash.
	file.open(path, File.READ)
	# Update the context after reading each chunk.
	while not file.eof_reached():
		ctx.update(file.get_buffer(CHUNK_SIZE))
	# Get the computed hash.
	var res = ctx.finish()
	# Print return hex string of the hashing
	return res.hex_encode()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	$FileDialog.popup_centered() # Replace with function body.


func _on_FileDialog_confirmed():
	$VBoxContainer/HBoxContainer/PathTextBox.text = $FileDialog.current_dir
	_update_base_dir($FileDialog.current_dir)
	_log( "Selected "+$FileDialog.current_dir+" as Omikron dir")

func _on_PathTextBox_text_changed(new_text):
	_update_base_dir(new_text)

func _update_base_dir(path):
	omikron_dir_path = path
	if OS.get_name() == "Windows":
		omikron_dir_path += "\\FONTS"
	else:
		omikron_dir_path += "/FONTS"

func _log(string):
	$VBoxContainer/TextBoxLog.text += string
	$VBoxContainer/TextBoxLog.text += "\n"

func _verify_dir():
	var dir: Directory = Directory.new()
	_log("Checking "+omikron_dir_path)
	if not dir.dir_exists(omikron_dir_path):
		_log("Directory "+omikron_dir_path+" is invalid")
		return false
	
	_log(omikron_dir_path+" Exists!")
	if dir.open(omikron_dir_path) != OK:
		_log("Couldn't open "+omikron_dir_path)
		return false
		
	_log("Checking "+good_fnt)
	if not dir.file_exists(good_fnt):
		_log("File "+good_fnt+" doesn't exist in "+omikron_dir_path)
		return false
		
	var font_hash = hash_file(join_to_path(good_fnt))
	if not font_hash == JOURNAL_MD5:
		_log("MD5 check for "+good_fnt+" failed, expected "+JOURNAL_MD5+" got "+font_hash)
		return false
	
	_log("All checks OK!")
	
	return dir
	
func backup_files(dir):
	_log("Renaming the fonts to be replaced")
	for file in bad_fnt:
		if dir.file_exists(file+"_bak"):
			_log("Skipping backup, "+file+" has already been saved")
			continue
		if dir.rename(file,file+"_bak") == OK:
			_log("Renaming of "+file+" OK!")
		else:
			_log("Error renaming "+file)  
	_log("Renaming done!")
	
func join_to_path(file):
	var bar ="/"
	if OS.get_name() == "Windows":
		bar = "\\"
	return omikron_dir_path+bar+file
	
func replace_files(dir):
	_log("Replacing fonts with "+good_fnt)
	for file in bad_fnt:
		if dir.copy(join_to_path(good_fnt),join_to_path(file)) == OK:
			_log("Replacing of "+file+" OK!")
		else:
			_log("Error replacing "+file)  
	_log("Replacing done!")
	
func _on_btn_go_pressed():
	#check if fonts/files are there
	# if there backup default .fnt files
	# copy journal.fnt
	var dir = _verify_dir()
	if not dir:
		_log("ERROR make sure that "+$VBoxContainer/HBoxContainer/PathTextBox.text+" is the correct directory")
		return false
	
	backup_files(dir)
	replace_files(dir)
	
	_log("Replacing of the font was a success, have fun!")
	


