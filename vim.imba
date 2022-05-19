import { readFileSync, writeFileSync } from 'fs'

let p = console.log
let stdin = process.stdin
let stdout = process.stdout
let args = process.argv

let filename
let buffer
let original_file
let command_text = ""

try
	filename = args[2]
	original_file = readFileSync(filename, "utf-8")
	buffer = original_file.split("\n")
catch
	p "Error reading file, quitting."
	process.exit!

let scroll_y = 0
let cursor_x = 0
let cursor_y = 0
let mode = "normal"

def write s
	stdout.write s

def clear_screen
	write "\x1bc"

def write_ansi_code s
	write "\x1b[{s}"

def draw_buffer
	draw buffer.slice(scroll_y, scroll_y + stdout.rows).join("\n"), cursor_x, cursor_y - scroll_y

def draw s, x, y
	clear_screen!
	write s
	write_ansi_code "{y + 1};{x + 1}f"

def move_cursor_up lines
	return if cursor_y < 1
	###
	if buffer[cursor_y - 1].length < cursor_x
		cursor_x = buffer[cursor_y - 1].length
	###
	cursor_y -= 1
	if cursor_y < scroll_y
		scroll_y -= 1

def move_cursor_down lines
	return unless cursor_y < buffer.length - 1
	###
	if buffer[cursor_y + 1].length < cursor_x
		cursor_x = buffer[cursor_y + 1].length
	###
	cursor_y += 1
	if cursor_y - scroll_y >= stdout.rows
		scroll_y += 1

def move_cursor_right lines
	# return unless cursor_x < buffer[cursor_y].length
	cursor_x += 1

def move_cursor_left lines
	return if cursor_x < 1
	cursor_x -= 1

def insert_text key
	let line = buffer[cursor_y]
	buffer[cursor_y] = line.slice(0, cursor_x) + key + line.slice(cursor_x)
	cursor_x += key.length

def delete_text
	let line = buffer[cursor_y]
	buffer[cursor_y] = line.slice(0, cursor_x - 1) + line.slice(cursor_x)
	cursor_x -= 1

def insert_tab
	insert_text "  "

def save_and_quit
	let save_was_successful = save!
	quit! if save_was_successful

def save
	try
		writeFileSync filename, buffer.join("\n")
		return yes
	catch
		return no

def soft_quit
	quit! if original_file === buffer.join("\n")

def quit
	clear_screen!
	process.exit!

def run_command
	switch command_text
		when "w"
			save!
		when "q"
			soft_quit!
		when "wq"
			save_and_quit!
		when "q!"
			quit!
	command_text = ""

def insert_newline
	buffer.splice(cursor_y + 1, 0, [])
	cursor_y += 1
	cursor_x = 0

def insert
	if cursor_x > buffer[cursor_y].length
		cursor_x = buffer[cursor_y].length
	mode = "insert"

let keymap_command = {
	27: do
		command_text = ""
		mode = "normal"
	13: do
		run_command!
		mode = "normal"
}

let keymap_insert = {
	27: do mode = "normal"
	127: delete_text
	9: insert_tab
	13: insert_newline
}

let keymap_normal = {
	'i': insert
	'h': move_cursor_left
	'j': move_cursor_down
	'k': move_cursor_up
	'l': move_cursor_right
	'I': do
		cursor_x = 0
		mode = "insert"
	'A': do
		cursor_x = buffer[cursor_y].length
		mode = "insert"
	'o': do
		insert_newline!
		mode = "insert"
	':': do mode = "command"
}

stdin.setRawMode(yes)
stdin.resume!
stdin.setEncoding('utf8')
draw_buffer!
stdin.on('data') do |key|
	if mode === "insert"
		try
			keymap_insert[key.charCodeAt(0)]!
		catch
			insert_text key
	elif mode === "normal"
		try
			keymap_normal[key]!
	elif mode === "command"
		try
			keymap_command[key.charCodeAt(0)]!
		catch
			command_text += key

	if mode === "command"
		draw ":" + command_text, command_text.length + 1, 0
	else
		draw_buffer!
