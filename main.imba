import { readFileSync, writeFileSync } from 'fs'
import { execSync } from 'child_process'
const readline = require('readline')

let cols = process.stdout.columns
let rows = process.stdout.rows

let filename
let buffer
let last_read

try
	filename = process.argv[2]
	last-read = readFileSync(filename, "utf-8")
	buffer = last-read.split("\n")
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
	while row < Math.min(scroll_y + rows, buffer.length)
		arr.push buffer[row].slice(scroll_x, scroll_x + cols)
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
	if scroll_y > 0 and cursor_y < scroll_y + (rows >>> 1)
		scroll_y -= 1
	cursor_x = Math.min(cursor_x, row!.length)

def move_cursor_down
	return unless cursor_y < buffer.length - 1
	cursor_y += 1
	if cursor_y - scroll_y >= rows
		scroll_y += 1
	cursor_x = Math.min(cursor_x, row!.length)

def move_cursor_right
	return unless cursor_x < row!.length
	cursor_x += 1
	if cursor_x - scroll_x >= cols
		scroll_x += 1

def move_cursor_right_max
	cursor_x = row!.length
	if cursor_x - scroll_x >= cols
		scroll_x += cursor_x - scroll_x - (cols >>> 1)

def move_cursor_left
	return if cursor_x < 1
	cursor_x -= 1
	if scroll_x > 0 and cursor_x < scroll_x + (cols >>> 1)
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

def find_files
	clear_screen!
	show_cursor!
	place_cursor 1, 1
	let file
	try
		filename = execSync 'fd | fzy'
		for char in filename.toString!
			insert_text char

let keymap_insert = {
	'escape': toggle_mode
	'backspace': delete_text
	'tab': do insert_text "  "
	'return': insert_newline
}

let keymap_normal = {
	'i': toggle_mode
	'h': move_cursor_left
	'j': move_cursor_down
	'k': move_cursor_up
	'l': move_cursor_right
	'w': save_and_quit
	'q': force_quit
	'f': find_files
}

process.stdin.setRawMode(yes)
process.stdin.resume!
smcup!
draw!
const options =
	input: process.stdin
	escapeCodeTimeout: 0
const rl = readline.createInterface options
readline.emitKeypressEvents process.stdin,rl
process.stdin.on('keypress') do
	if mode === "normal"
		if keymap_normal.hasOwnProperty $1
			keymap_normal[$1]!
	else
		if keymap_insert.hasOwnProperty $2.name
			keymap_insert[$2.name]!
		else
			insert_text $1
	draw!
