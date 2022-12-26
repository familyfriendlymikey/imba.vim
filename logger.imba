import fs from 'fs'

import { Console } from 'console'

const file-logger = new Console(
	stdout: fs.createWriteStream("log.txt")
)

global.L = file-logger.log

