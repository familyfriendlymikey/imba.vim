import fs from 'fs'
import cp from 'child_process'
import term from './term'
const readline = require('readline')

global.L = do
	fs.writeFileSync "log.txt", $1

class App

	keymap-insert = {
		'escape': toggle-mode.bind(this)
		'backspace': delete-text.bind(this)
		'tab': insert-tab.bind(this)
		'return': insert-newline.bind(this)
	}

	keymap-normal = {
		'i': toggle-mode.bind(this)
		'h': move-cursor-left.bind(this)
		'j': move-cursor-down.bind(this)
		'k': move-cursor-up.bind(this)
		'l': move-cursor-right.bind(this)
		'w': save-and-quit.bind(this)
		'q': force-quit.bind(this)
		'f': find-files.bind(this)
	}

	filename
	buffer
	last-read = ""

	scroll-y = 0
	scroll-x = 0
	cursor-x = 0
	cursor-y = 0
	mode = "normal"

	get row
		buffer[cursor-y]

	def constructor
		try
			filename = process.argv[2]
			if fs.existsSync filename
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
				if keymap-normal.hasOwnProperty $1
					keymap-normal[$1]!
			else
				if keymap-insert.hasOwnProperty $2.name
					keymap-insert[$2.name]!
				else
					insert-text $1
			draw!

	def draw
		let arr = []
		let row = scroll-y
		while row < Math.min(scroll-y + term.rows, buffer.length)
			arr.push buffer[row].slice(scroll-x, scroll-x + term.cols)
			row += 1
		term.hide-cursor!
		term.clear-screen!
		term.place-cursor 1, 1
		process.stdout.write arr.join("\n")
		term.place-cursor (cursor-x - scroll-x + 1), (cursor-y - scroll-y + 1)
		term.show-cursor!

	def move-cursor-up
		return if cursor-y < 1
		cursor-y -= 1
		if scroll-y > 0 and cursor-y < scroll-y
			scroll-y -= 1
		cursor-x = Math.min(cursor-x, row.length)

	def move-cursor-down
		return unless cursor-y < buffer.length - 1
		cursor-y += 1
		if cursor-y - scroll-y >= term.rows
			scroll-y += 1
		cursor-x = Math.min(cursor-x, row.length)

	def move-cursor-right
		return unless cursor-x < row.length
		cursor-x += 1
		if cursor-x - scroll-x >= term.cols
			scroll-x += 1

	def move-cursor-right-max
		cursor-x = row.length
		if cursor-x - scroll-x >= term.cols
			scroll-x += cursor-x - scroll-x - (term.cols >>> 1)

	def move-cursor-left
		return if cursor-x < 1
		cursor-x -= 1
		if scroll-x > 0 and cursor-x < scroll-x + (term.cols >>> 1)
			scroll-x -= 1

	def insert-text key
		buffer[cursor-y] = row.slice(0, cursor-x) + key + row.slice(cursor-x)
		move-cursor-right!

	def delete-text
		if cursor-x < 1 and cursor-y > 0
			let y = cursor-y
			move-cursor-up!
			move-cursor-right-max!
			buffer.splice(y - 1, 2, buffer[y - 1] + buffer[y])
		else
			buffer[cursor-y] = row.slice(0, cursor-x - 1) + row.slice(cursor-x)
			move-cursor-left!

	def save-and-quit
		try
			fs.writeFileSync filename, buffer.join("\n")
			last-read = fs.readFileSync(filename, "utf-8")
			force-quit!

	def force-quit
		term.clear-screen!
		term.show-cursor!
		term.rmcup!
		process.exit!

	def insert-tab
		insert-text "  "

	def insert-newline
		let first = row.slice(0, cursor-x)
		let rest = row.slice(cursor-x)
		buffer.splice(cursor-y, 1, first, rest)
		move-cursor-down!
		cursor-x = 0
		scroll-x = 0

	def toggle-mode
		if mode === "normal"
			if cursor-x > row.length
				cursor-x = row.length
				if row.length < scroll-x
					scroll-x = cursor-x
			# process.stdout.write "\x1b[4 q"
			mode = "insert"
		else
			# process.stdout.write "\x1b[1 q"
			mode = "normal"

	def find-files
		term.clear-screen!
		term.show-cursor!
		term.place-cursor 1, 1
		let file
		try
			filename = cp.execSync 'fd | fzy'
			for char in filename.toString!
				insert-text char

global.App = new App
