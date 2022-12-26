export default new class Term

	get cols
		process.stdout.columns

	get rows
		process.stdout.rows

	def clear-screen
		# we don't use "\x1bc" here because that
		# clears scrollback for the entire terminal session
		process.stdout.write "\x1b[2J"

	def place-cursor x, y
		process.stdout.write "\x1b[{y};{x}H"

	def hide-cursor
		process.stdout.write "\x1b[?25l"

	def show-cursor
		process.stdout.write "\x1b[?25h"

	def smcup
		# switches to an alternate screen buffer so as to not
		# interfere with the user's current terminal window
		process.stdout.write "\x1b[?1049h"

	def rmcup
		# switches back, see smcup
		process.stdout.write "\x1b[?1049l"

