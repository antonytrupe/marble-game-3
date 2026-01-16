class_name MarbleAge
extends Node

const SECONDS_IN_TURN: int = 6

const SECONDS_IN_MINUTE: int = 60
const SECONDS_IN_HOUR: int = SECONDS_IN_MINUTE * MINUTES_IN_HOUR
const SECONDS_IN_DAY: int = SECONDS_IN_HOUR * HOURS_IN_DAY
const SECONDS_IN_MONTH: int = SECONDS_IN_DAY * DAYS_IN_MONTH
const SECONDS_IN_YEAR: int = SECONDS_IN_MONTH * MONTHS_IN_YEAR
const MINUTES_IN_HOUR: int = 60
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

func get_month()->int:
	@warning_ignore("integer_division")
	var month_of_year: int = int(age) % (MarbleAge.SECONDS_IN_HOUR * MarbleAge.HOURS_IN_DAY * MarbleAge.DAYS_IN_MONTH * MarbleAge.MONTHS_IN_YEAR) / (MarbleAge.SECONDS_IN_MONTH)

	return month_of_year

func get_day_of_week()->int:
	var day_of_month=get_day_of_month()
	var day_of_week:int = (day_of_month - 1) % MarbleAge.DAYS_IN_WEEK
	return day_of_week

func get_day_of_month()->int:
	@warning_ignore("integer_division")
	var day_of_month: int = int(age) % (MarbleAge.SECONDS_IN_MONTH) / (MarbleAge.SECONDS_IN_DAY) + 1
	return day_of_month

func get_week_of_month()->int:
	var day_of_month=get_day_of_month()
	@warning_ignore("integer_division")
	var week_of_month:int = (day_of_month - 1) / MarbleAge.DAYS_IN_WEEK
	return week_of_month

func get_years()->int:
	return 0
