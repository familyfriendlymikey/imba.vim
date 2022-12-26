import fs from 'fs'

export default class TextBuffer

	def constructor filename
		return unless fs.existsSync filename
		this.filename = filename
		content = fs.readFileSync(filename,"utf-8").split('\n')

	filename
	content = []
	mode = 'normal'

	scroll-y = 0
	scroll-x = 0
	cursor-x = 0
	cursor-y = 0
	cursor-x-last = 0

	get row
		content[cursor-y]

	get length
		content.length

