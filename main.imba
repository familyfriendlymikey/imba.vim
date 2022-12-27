import fs from 'fs'
import cp from 'child_process'
import readline from 'readline'
import 'colors'

import * as utils from './utils'
import term from './term'
import TextBuffer from './buffer'
# import { keymap-normal, keymap-insert } from './keymap'

global.L = console.error

class App

	keymap-insert = {
		'escape': toggle-mode.bind(this)
		'backspace': delete-text.bind(this)
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
		'A': move-cursor-right-max-insert.bind(this)
		'I': move-cursor-left-max-insert.bind(this)
		'o': new-line-below-insert.bind(this)
		'O': new-line-above-insert.bind(this)
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

	def update-scroll

		if buffer.cursor-y - buffer.scroll-y >= term.rows
			buffer.scroll-y += 1
		elif buffer.scroll-y > 0 and buffer.cursor-y < buffer.scroll-y
			buffer.scroll-y -= 1

		if buffer.cursor-x - buffer.scroll-x >= term.cols
			buffer.scroll-x += 1
		elif buffer.scroll-x > 0 and buffer.cursor-x < buffer.scroll-x
			buffer.scroll-x -= 1

	def replace-content arr
		arr = arr.map do
			$1 = $1.replace /\ +$/, do
				'~'.repeat($1.length).cyan
			$1 = $1.replace /\t/g, '.'.cyan + ' '

	get display-buffer
		let top = buffer.scroll-y
		let bottom = Math.min(buffer.scroll-y + term.rows,buffer.content.length)
		let out = buffer.content.slice(top,bottom)
		out = out.map do(row)
			let left = buffer.scroll-x
			let right = Math.min(buffer.scroll-x + term.cols,row.length)
			row.slice(left,right)
		replace-content(out).join '\n'

	get cursor-display-pos
		let text = buffer.row.slice(0,buffer.cursor-x)
		text = text.replaceAll('\t','  ')
		text.length

	def draw
		term.clear-screen!
		term.place-cursor 1, 1
		term.write display-buffer
		term.place-cursor (cursor-display-pos - buffer.scroll-x + 1), (buffer.cursor-y - buffer.scroll-y + 1)
		term.flush!

	def move-cursor x, y

		if x isnt buffer.cursor-x
			buffer.cursor-x-last = Math.min(Math.max(x,0),buffer.row.length)

		return if x < 0
		return if y < 0
		return if x > buffer.row.length
		return if y > buffer.content.length - 1

		buffer.cursor-y = y
		buffer.cursor-x = Math.min buffer.row.length, buffer.cursor-x-last

		update-scroll!

	def move-cursor-up
		move-cursor buffer.cursor-x, buffer.cursor-y - 1

	def move-cursor-down
		move-cursor buffer.cursor-x, buffer.cursor-y + 1

	def move-cursor-right
		move-cursor buffer.cursor-x + 1, buffer.cursor-y

	def move-cursor-left
		move-cursor buffer.cursor-x - 1, buffer.cursor-y

	def move-cursor-right-max
		move-cursor buffer.row.length, buffer.cursor-y

	def move-cursor-right-max-insert
		move-cursor-right-max!
		toggle-mode!

	def move-cursor-left-max
		let start = buffer.row.search /\S/
		if start is -1 then start = 0
		move-cursor start, buffer.cursor-y

	def move-cursor-left-max-insert
		move-cursor-left-max!
		toggle-mode!

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
		term.flush!
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
		term.flush!

	def toggle-mode
		if buffer.mode is "normal"
			if buffer.cursor-x > buffer.row.length
				buffer.cursor-x = buffer.row.length
				if buffer.row.length < buffer.scroll-x
					buffer.scroll-x = buffer.cursor-x
			term.write "\x1b[4 q"
			buffer.mode = "insert"
		else
			term.write "\x1b[0 q"
			buffer.mode = "normal"
		term.flush!

	def new-line-below-insert
		buffer.content.splice(buffer.cursor-y + 1,0,'')
		move-cursor buffer.cursor-x, buffer.cursor-y + 1
		toggle-mode!

	def new-line-above-insert
		buffer.content.splice(buffer.cursor-y,0,'')
		toggle-mode!

global.App = new App
