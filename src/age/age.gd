class_name MarbleAge
extends Resource

const SECONDS_IN_TURN: int = 6

const SECONDS_IN_MINUTE: int = 60
const MINUTES_IN_HOUR: int = 60
const SECONDS_IN_HOUR: int = SECONDS_IN_MINUTE * MINUTES_IN_HOUR
const SECONDS_IN_DAY: int = SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY
const SECONDS_IN_YEAR: int = SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY * WEEKS_IN_MONTH * MONTHS_IN_YEAR
const HOURS_IN_DAY: int = 24
const DAYS_IN_WEEK: int = 7
const WEEKS_IN_MONTH: int = 4
const DAYS_IN_MONTH: int = DAYS_IN_WEEK * WEEKS_IN_MONTH
const MONTHS_IN_YEAR: int = 10
const MONTHS = [
	"March", # 1
	"April", # 2
	"May", #
	"June", #
	"July", #
	"August", # 6
	"September", # 7
	"October", # 8
	"November", # 9
	"December" # 10
	]

## seconds since creation, taking warp bubbles into account
@export var age: float = 0

func get_month():
	return 0

func get_day_of_month():
	return 0

func get_years():
	return 0
