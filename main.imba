import fs from 'fs'
import cp from 'child_process'
import term from './term'
const readline = require('readline')

global.L = do
	fs.writeFileSync "log.txt", $1

class App

	keymap_insert = {
		'escape': toggle_mode.bind(this)
		'backspace': delete_text.bind(this)
		'tab': insert-tab.bind(this)
		'return': insert_newline.bind(this)
	}

	keymap_normal = {
		'i': toggle_mode.bind(this)
		'h': move_cursor_left.bind(this)
		'j': move_cursor_down.bind(this)
		'k': move_cursor_up.bind(this)
		'l': move_cursor_right.bind(this)
		'w': save_and_quit.bind(this)
		'q': force_quit.bind(this)
		'f': find_files.bind(this)
	}

	filename
	buffer
	last_read

	scroll_y = 0
	scroll_x = 0
	cursor_x = 0
	cursor_y = 0
	mode = "normal"

	get row
		buffer[cursor_y]

	def constructor
		try
			filename = process.argv[2]
			last-read = fs.readFileSync(filename, "utf-8")
			buffer = last-read.split("\n")
		catch
			process.exit!

		process.stdin.setRawMode(yes)
		process.stdin.resume!
		term.smcup!
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

	def draw
		let arr = []
		let row = scroll_y
		while row < Math.min(scroll_y + term.rows, buffer.length)
			arr.push buffer[row].slice(scroll_x, scroll_x + term.cols)
			row += 1
		term.hide_cursor!
		term.clear_screen!
		term.place_cursor 1, 1
		process.stdout.write arr.join("\n")
		term.place_cursor (cursor_x - scroll_x + 1), (cursor_y - scroll_y + 1)
		term.show_cursor!

	def move_cursor_up
		return if cursor_y < 1
		cursor_y -= 1
		if scroll_y > 0 and cursor_y < scroll_y
			scroll_y -= 1
		cursor_x = Math.min(cursor_x, row.length)

	def move_cursor_down
		return unless cursor_y < buffer.length - 1
		cursor_y += 1
		if cursor_y - scroll_y >= term.rows
			scroll_y += 1
		cursor_x = Math.min(cursor_x, row.length)

	def move_cursor_right
		return unless cursor_x < row.length
		cursor_x += 1
		if cursor_x - scroll_x >= term.cols
			scroll_x += 1

	def move_cursor_right_max
		cursor_x = row.length
		if cursor_x - scroll_x >= term.cols
			scroll_x += cursor_x - scroll_x - (term.cols >>> 1)

	def move_cursor_left
		return if cursor_x < 1
		cursor_x -= 1
		if scroll_x > 0 and cursor_x < scroll_x + (term.cols >>> 1)
			scroll_x -= 1

	def insert_text key
		buffer[cursor_y] = row.slice(0, cursor_x) + key + row.slice(cursor_x)
		move_cursor_right!

	def delete_text
		if cursor_x < 1 and cursor_y > 0
			let y = cursor_y
			move_cursor_up!
			move_cursor_right_max!
			buffer.splice(y - 1, 2, buffer[y - 1] + buffer[y])
		else
			buffer[cursor_y] = row.slice(0, cursor_x - 1) + row.slice(cursor_x)
			move_cursor_left!

	def save_and_quit
		try
			fs.writeFileSync filename, buffer.join("\n")
			last_read = fs.readFileSync(filename, "utf-8")
			force_quit!

	def force_quit
		term.clear_screen!
		term.show_cursor!
		term.rmcup!
		process.exit!

	def insert-tab
		insert_text "  "

	def insert_newline
		let first = row.slice(0, cursor_x)
		let rest = row.slice(cursor_x)
		buffer.splice(cursor_y, 1, first, rest)
		move_cursor_down!
		cursor_x = 0
		scroll_x = 0

	def toggle_mode
		if mode === "normal"
			if cursor_x > row.length
				cursor_x = row.length
				if row.length < scroll_x
					scroll_x = cursor_x
			# process.stdout.write "\x1b[4 q"
			mode = "insert"
		else
			# process.stdout.write "\x1b[1 q"
			mode = "normal"

	def find_files
		term.clear_screen!
		term.show_cursor!
		term.place_cursor 1, 1
		let file
		try
			filename = cp.execSync 'fd | fzy'
			for char in filename.toString!
				insert_text char

global.App = new App
