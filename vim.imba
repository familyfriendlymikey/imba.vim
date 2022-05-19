import { readFileSync, writeFileSync } from 'fs'

let filename
let buffer
let last_read

try
	filename = process.argv[2]
	last_read = readFileSync(filename, "utf-8")
	buffer = last_read.split("\n")
catch
	process.exit!

let scroll_y = 0
let scroll_x = 0
let cursor_x = 0
let cursor_y = 0
let mode = "normal"

def clear_screen
	# we don't use "\x1bc" here because that
	# clears scrollback for the entire terminal session
	process.stdout.write "\x1b[2J"

def place_cursor x, y
	process.stdout.write "\x1b[{y};{x}H"

def hide_cursor
	process.stdout.write "\x1b[?25l"

def show_cursor
	process.stdout.write "\x1b[?25h"

def smcup
	# switches to an alternate screen buffer so as to not
	# interfere with the user's current terminal window
	process.stdout.write "\x1b[?1049h"

def rmcup
	# switches back, see smcup
	process.stdout.write "\x1b[?1049l"

def row
	buffer[cursor_y]

def draw
	let arr = []
	let row = scroll_y
	while row < Math.min(scroll_y + process.stdout.rows, buffer.length)
		arr.push buffer[row].slice(scroll_x, scroll_x + process.stdout.columns)
		row += 1
	hide_cursor!
	clear_screen!
	place_cursor 1, 1
	process.stdout.write arr.join("\n")
	place_cursor (cursor_x - scroll_x + 1), (cursor_y - scroll_y + 1)
	show_cursor!

def move_cursor_up
	return if cursor_y < 1
	cursor_y -= 1
	if scroll_y > 0 and cursor_y < scroll_y + (process.stdout.rows >>> 1)
		scroll_y -= 1
	cursor_x = Math.min(cursor_x, row!.length)

def move_cursor_down
	return unless cursor_y < buffer.length - 1
	cursor_y += 1
	if cursor_y - scroll_y >= process.stdout.rows
		scroll_y += 1
	cursor_x = Math.min(cursor_x, row!.length)

def move_cursor_right
	return unless cursor_x < row!.length
	cursor_x += 1
	if cursor_x - scroll_x >= process.stdout.columns
		scroll_x += 1

def move_cursor_right_max
	cursor_x = row!.length
	if cursor_x - scroll_x >= process.stdout.columns
		scroll_x += cursor_x - scroll_x - (process.stdout.columns >>> 1)

def move_cursor_left
	return if cursor_x < 1
	cursor_x -= 1
	if scroll_x > 0 and cursor_x < scroll_x + (process.stdout.columns >>> 1)
		scroll_x -= 1

def insert_text key
	buffer[cursor_y] = row!.slice(0, cursor_x) + key + row!.slice(cursor_x)
	move_cursor_right!

def delete_text
	if cursor_x < 1 and cursor_y > 0
		let y = cursor_y
		move_cursor_up!
		move_cursor_right_max!
		buffer.splice(y - 1, 2, buffer[y - 1] + buffer[y])
	else
		buffer[cursor_y] = row!.slice(0, cursor_x - 1) + row!.slice(cursor_x)
		move_cursor_left!

def save_and_quit
	try
		writeFileSync filename, buffer.join("\n")
		last_read = readFileSync(filename, "utf-8")
		force_quit!

def force_quit
	clear_screen!
	show_cursor!
	rmcup!
	process.exit!

def insert_newline
	let first = row!.slice(0, cursor_x)
	let rest = row!.slice(cursor_x)
	buffer.splice(cursor_y, 1, first, rest)
	move_cursor_down!
	cursor_x = 0
	scroll_x = 0

def toggle_mode
	if mode === "normal"
		if cursor_x > row!.length
			cursor_x = row!.length
			if row!.length < scroll_x
				scroll_x = cursor_x
		process.stdout.write "\x1b[4 q"
		mode = "insert"
	else
		process.stdout.write "\x1b[1 q"
		mode = "normal"

let keymap_insert = {
	27: toggle_mode # ESC
	127: delete_text # BS
	9: do insert_text "  " # TAB
	13: insert_newline # CR
}

let keymap_normal = {
	'i': toggle_mode
	'h': move_cursor_left
	'j': move_cursor_down
	'k': move_cursor_up
	'l': move_cursor_right
	"w": save_and_quit
	"q": force_quit
}

process.stdin.setRawMode(yes)
process.stdin.resume!
process.stdin.setEncoding('utf8')
smcup!
draw!
process.stdin.on('data') do |key|
	if mode === "normal"
		if keymap_normal.hasOwnProperty key
			keymap_normal[key]!
	else
		let keycode = key.charCodeAt(0)
		if keymap_insert.hasOwnProperty keycode
			keymap_insert[keycode]!
		else
			insert_text key
	draw!
