import fs from 'fs'
import cp from 'child_process'
import readline from 'readline'

import term from './term'
import TextBuffer from './buffer'
# import { keymap-normal, keymap-insert } from './keymap'

global.L = console.error

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
		'A': move-cursor-end-insert.bind(this)
	}

	files = []

	get buffer
		files[0]

	def constructor
		try
			filename = process.argv[2]
			let buf = new TextBuffer(filename)
			files.push buf
		catch e
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
			if buffer.mode is "normal"
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
		let row = buffer.scroll-y
		while row < Math.min(buffer.scroll-y + term.rows, buffer.content.length)
			arr.push buffer.content[row].slice(buffer.scroll-x, buffer.scroll-x + term.cols)
			row += 1
		term.hide-cursor!
		term.clear-screen!
		term.place-cursor 1, 1
		process.stdout.write arr.join("\n")
		term.place-cursor (buffer.cursor-x - buffer.scroll-x + 1), (buffer.cursor-y - buffer.scroll-y + 1)
		term.show-cursor!

	def move-cursor-end-insert
		move-cursor-end!
		toggle-mode!

	def move-cursor-end
		buffer.cursor-x = buffer.row.length

	def move-cursor-up
		return if buffer.cursor-y < 1
		buffer.cursor-y -= 1
		if buffer.scroll-y > 0 and buffer.cursor-y < buffer.scroll-y
			buffer.scroll-y -= 1
		buffer.cursor-x = Math.min(buffer.cursor-x, buffer.row.length)

	def move-cursor-down
		return unless buffer.cursor-y < buffer.content.length - 1
		buffer.cursor-y += 1
		if buffer.cursor-y - buffer.scroll-y >= term.rows
			buffer.scroll-y += 1
		buffer.cursor-x = Math.min(buffer.cursor-x, buffer.row.length)

	def move-cursor-right
		return unless buffer.cursor-x < buffer.row.length
		buffer.cursor-x += 1
		if buffer.cursor-x - buffer.scroll-x >= term.cols
			buffer.scroll-x += 1

	def move-cursor-right-max
		buffer.cursor-x = buffer.row.length
		if buffer.cursor-x - buffer.scroll-x >= term.cols
			buffer.scroll-x += buffer.cursor-x - buffer.scroll-x - (term.cols >>> 1)

	def move-cursor-left
		return if buffer.cursor-x < 1
		buffer.cursor-x -= 1
		if buffer.scroll-x > 0 and buffer.cursor-x < buffer.scroll-x + (term.cols >>> 1)
			buffer.scroll-x -= 1

	def insert-text key
		buffer.content[buffer.cursor-y] = buffer.row.slice(0, buffer.cursor-x) + key + buffer.row.slice(buffer.cursor-x)
		move-cursor-right!

	def delete-text
		if buffer.cursor-x < 1 and buffer.cursor-y > 0
			let y = buffer.cursor-y
			move-cursor-up!
			move-cursor-right-max!
			buffer.content.splice(y - 1, 2, buffer.content[y - 1] + buffer.content[y])
		else
			buffer.content[buffer.cursor-y] = buffer.row.slice(0, buffer.cursor-x - 1) + buffer.row.slice(buffer.cursor-x)
			move-cursor-left!

	def save-and-quit
		try
			fs.writeFileSync filename, buffer.content.join("\n")
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
		let first = buffer.row.slice(0, buffer.cursor-x)
		let rest = buffer.row.slice(buffer.cursor-x)
		buffer.content.splice(buffer.cursor-y, 1, first, rest)
		move-cursor-down!
		buffer.cursor-x = 0
		buffer.scroll-x = 0

	def find-files
		term.clear-screen!
		term.show-cursor!
		term.place-cursor 1, 1
		let file
		try
			filename = cp.execSync 'fd | fzy'
			for char in filename.toString!
				insert-text char

	def toggle-mode
		L buffer
		if buffer.mode is "normal"
			if buffer.cursor-x > buffer.row.length
				buffer.cursor-x = buffer.row.length
				if buffer.row.length < buffer.scroll-x
					buffer.scroll-x = buffer.cursor-x
			process.stdout.write "\x1b[4 q"
			buffer.mode = "insert"
		else
			process.stdout.write "\x1b[1 q"
			buffer.mode = "normal"


global.App = new App
