export default new class Term

	buf = ""

	def flush
		process.stdout.write buf
		buf = ""

	def write
		buf += $1

	get cols
		process.stdout.columns

	get rows
		process.stdout.rows

	def clear-screen
		buf += "\x1b[2J"

	def place-cursor x, y
		buf += "\x1b[{y};{x}H"

	def hide-cursor
		buf += "\x1b[?25l"

	def show-cursor
		buf += "\x1b[?25h"

	def smcup
		buf += "\x1b[?1049h"

	def rmcup
		buf += "\x1b[?1049l"

