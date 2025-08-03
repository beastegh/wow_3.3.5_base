local NUMBER_PATTERN = " ^ %s*([+-]?%d*%.?%d+)"
local OPERATOR_PATTERN = " ^ %s*(.)"
local END_PATTERN = " ^ %s*$"
local NUMBER_ERROR = "No valid number at position %d"
local OPERATOR_ERROR = "Unrecognized operator at position %d: '%s'"
local errorState = false

local function reportError(message)
  print(message)
  errorState = true
end

local operators = {
  ["+"] = function(a, b)
    return a + b
  end,
  ["-"] = function(a, b)
    return a - b
  end,
  ["*"] = function(a, b)
    return a * b
  end,
  ["/"] = function(a, b)
    return a / b
  end
}

local function calculate(number1, ...)
  if errorState then
    return
  end

  for i = 1, select("#", ...), 2 do
    local operatorFunc, number2 = select(i, ...)
    number1 = operatorFunc(number1, number2)
  end
  return number1
end


local function getpairs(message, start)
  local _, operatorFinish, operator = message:find(OPERATOR_PATTERN, start)
  local operatorFunction = operators[operator]

  if not operatorFunction then
    reportError(OPERATOR_ERROR:format(start, operator))
    return
  end

  operatorFinish = operatorFinish + 1
  local _, numberFinish, number = message:find(NUMBER_PATTERN, operatorFinish)

  if not number then
    reportError(NUMBER_ERROR:format(operatorFinish))
    return
  end

  numberFinish = numberFinish + 1

  if message:match(END_PATTERN, numberFinish) then
    return operatorFunction, number
  else
    return operatorFunction, number, getpairs(message, numberFinish)
  end
end

local function tokenize(message)
  local _, finish, number = message:find(NUMBER_PATTERN)

  if not number then
    reportError(NUMBER_ERROR:format(1))
    return
  end

  finish = finish + 1

  if message:match(END_PATTERN, finish) == "" then
    return number
  else
    return number, getpairs(message, finish)
  end
end

SLASH_SIMPLECALC1 = "/calculate"
SLASH_SIMPLECALC2 = "/calc"
SlashCmdList["SIMPLECALC"] = function(message)
  errorState = false
  print(calculate(tokenize(message)))
end



