📘 Реакция на графические обновления с помощью OnUpdate

  Хотя большая часть кода в World of Warcraft основана на системе событий, бывают ситуации, когда код необходимо выполнять регулярно (например, с привязкой ко времени).

  В World of Warcraft нет простой API-функции для реализации такой логики, однако это можно сделать с помощью скриптов OnUpdate.

  Например, OnUpdate-скрипты можно использовать для следующих задач:
    Отложенное выполнение кода на определённое время
    Объединение часто срабатывающих событий в одну партию для обработки
    Повторяющееся выполнение кода с интервалом по времени
  
  В этой главе рассматривается система графических обновлений, лежащая в основе OnUpdate, и приводятся примеры простых аддонов, реализующих каждый из этих вариантов.

📘 Понимание графических обновлений

  Один из стандартных показателей производительности графики в игре, такой как World of Warcraft, — это частота кадров (FPS), измеряемая в кадрах в секунду. Графический движок перерисовывает экран с этой частотой, чтобы отобразить изменения в интерфейсе и игровом мире.

  Вы можете увидеть свою текущую частоту кадров (см. рисунок), нажав Ctrl+R.

  Каждый раз при перерисовке экрана выполняется скрипт OnUpdate для каждого видимого фрейма (даже если у него нет графических компонентов). Кроме того, в OnUpdate передаётся аргумент, указывающий, сколько времени прошло с момента последнего обновления экрана.

  Вместе всё это можно использовать для создания очень простого, но эффективного таймера.
    👉 https://live.staticflickr.com/65535/54650597032_0f8d51abae_t.jpg

📘 Отложенное выполнение кода с помощью OnUpdate

  Представим, что у вас есть функция (например, произнести случайную колкость), которую вы хотите выполнить с задержкой. Вы можете написать вспомогательную функцию, использующую OnUpdate, чтобы выполнить код позже. Введите в игре следующий код:
  
    if not DelayFrame then
      DelayFrame = CreateFrame("Frame")
      DelayFrame:Hide()
    end
  
    function Delay(delay, func)
      DelayFrame.func = func
      DelayFrame.delay = delay
      DelayFrame:Show()
    end

    DelayFrame:SetScript("OnUpdate", function(self, elapsed)
      self.delay = self.delay - elapsed
       
      if self.delay <= 0 then
        self:Hide()
        self.func()
      end
    end)
    
  Этот код определяет функцию Delay, принимающую количество секунд и функцию, которую нужно вызвать после этой задержки. Фрейм DelayFrame следит за прошедшим временем с помощью OnUpdate и вызывает переданную функцию, когда время истекает.

  Теперь пример использования Delay — небольшой скрипт, который будет отправлять колкие реплики в бою:

    if not TauntFrame then
      TauntFrame = CreateFrame("Frame")
    end

    local tauntMessages = {
      "Is that the best you can do?",
      "My grandmother can hit harder than that!",
      "Now you're making me angry!",
      "Was that supposed to hurt?",
      "Vancleef pay big for your head!",
      "You too slow! Me too strong!",
    }

    TauntFrame.CHANCE = 0.5 -- шанс, что сообщение сработает
    TauntFrame.DELAY = 3.0 -- максимальная задержка перед сообщением

    local isDelayed = false

    local function sendTauntMessage()
      local msgId = math.random(#tauntMessages)
      SendChatMessage(tauntMessages[msgId], "SAY")
      isDelayed = false
    end

    TauntFrame:RegisterEvent("UNIT_COMBAT")

    TauntFrame:SetScript("OnEvent", function(self, event, unit, action, ...)
      if unit == "player" and action ~= "HEAL" and not isDelayed then
        local chance = math.random(100)

        if chance <= (100 * self.CHANCE) then
          local delayTime = math.random() * self.DELAY
          Delay(delayTime, sendTauntMessage)
          isDelayed = true
        end
      end
    end)

  👉 Что делает этот код:
    Создаёт фрейм TauntFrame для обработки событий.
    Определяет список колкостей.
    Настраивает два параметра: 
      CHANCE (шанс на срабатывание)
      DELAY (задержка).
    Создаёт функцию sendTauntMessage, выбирающую случайную реплику и отправляющую её в чат.

  При срабатывании события UNIT_COMBAT, если атакован игрок и нет уже запущенной задержки, скрипт с определённым шансом запускает отправку фразы с задержкой.

  На изображении видно, как эти фразы отправляются прямо в бою:
  👉 https://live.staticflickr.com/65535/54651456726_0b3d49cee5_m.jpg

  Ты можешь менять параметры TauntFrame.CHANCE и TauntFrame.DELAY прямо во время работы аддона, подбирая поведение под себя.
  
📘 Группировка событий для предотвращения избыточной обработки

  Следующий простой фрагмент кода отслеживает инвентарь игрока и предупреждает его, когда остаётся слишком мало свободного места. Для этого используется событие BAG_UPDATE, которое сообщает об изменениях в сумках игрока.
  
  if not BagWatchFrame then
  	BagWatchFrame = CreateFrame("Frame")
  end
  
  BagWatchFrame.WARN_LEVEL = 0.2
  BagWatchFrame.message = "You are running low on bag space!"
  BagWatchFrame.fullMessage = "Your bags are full!"
  
  local function bagWatch_OnEvent(self, event, bag, ...)
  	local maxSlots, freeSlots = 0, 0

  	for idx = 0, 4 do
  		maxSlots = maxSlots + GetContainerNumSlots(idx)
  		freeSlots = freeSlots + GetContainerNumFreeSlots(idx)
  	end
  	
  	local percFree = freeSlots / maxSlots
  	local msg
  
  	if percFree == self.percFree then
  		-- Не повторять предупреждение при том же уровне
  	elseif percFree == 0 then
  		msg = BagWatchFrame.fullMessage
  	elseif percFree <= self.WARN_LEVEL then
  		msg = BagWatchFrame.message
  	end
  
  	if msg then
  		RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
  	end
  
  	self.percFree = percFree
  end
  
  BagWatchFrame:RegisterEvent("BAG_UPDATE")
  BagWatchFrame:SetScript("OnEvent", bagWatch_OnEvent)

  👉 Что делает этот код:
    Предупреждает игрока, если свободных ячеек в сумках меньше 20%.
    Определяет общее и свободное количество слотов через GetContainerNumSlots() и GetContainerNumFreeSlots().
    Выводит сообщение с помощью RaidNotice_AddMessage().
  
  Пример визуального предупреждения:
    👉 https://live.staticflickr.com/65535/54651824565_c26d9e120b_w.jpg
    
  👉 Проблема:
    Если вы используете Менеджер снаряжения (Equipment Manager) — систему, позволяющую сохранять и переключать наборы экипировки — вы можете столкнуться с тем, что это предупреждение появляется многократно подряд. Это происходит потому, что BAG_UPDATE срабатывает много раз за короткий промежуток, когда экипировка быстро надевается или снимается.
  
  В зависимости от задержки (пинга), количества предметов и количества свободных слотов, это может привести к множеству повторных сообщений. Чтобы решить эту проблему — можно сгруппировать события с помощью OnUpdate, о чём рассказывается в следующем разделе.

📘 Группировка нескольких событий

  Оригинальный код можно изменить так, чтобы он не запускал проверку сумок немедленно, а откладывал её выполнение на некоторое время, используя событие OnUpdate. Отредактируй код следующим образом, обратив внимание на отличия от предыдущей версии:
  
    if not BagWatchFrame then
      BagWatchFrame = CreateFrame("Frame")
    end
    
    BagWatchFrame.THROTTLE = 0.5
    BagWatchFrame.WARN_LEVEL = 0.2
    BagWatchFrame.message = "You are running low on bag space!"
    BagWatchFrame.fullMessage = "Your bags are full!"
  
    local function bagWatch_ScanBags(frame)
      local maxSlots, freeSlots = 0, 0
  
      for idx = 0, 4 do
        maxSlots = maxSlots + GetContainerNumSlots(idx)
        freeSlots = freeSlots + GetContainerNumFreeSlots(idx)
      end
      
      local percFree = freeSlots / maxSlots
      local msg
  
      if percFree == frame.percFree then
        -- Не предупреждать пользователя повторно при том же уровне заполненности
      elseif percFree == 0 then
        msg = frame.fullMessage
      elseif percFree <= frame.WARN_LEVEL then
        msg = frame.message
      end
  
      if msg then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
      end
      frame.percFree = percFree
    end
    
    BagWatchFrame:RegisterEvent("BAG_UPDATE")
    local counter = 0
    
    BagWatchFrame:SetScript("OnUpdate", function(self, elapsed)
      counter = counter + elapsed
      if counter >= self.THROTTLE then
        bagWatch_ScanBags(self)
        counter = 0
        self:Hide()
      end
    end)
    
    BagWatchFrame:SetScript("OnEvent", function(self, event, ...)
      BagWatchFrame:Show()
    end)
    
  Вместо того чтобы вызывать функцию сканирования сумок напрямую (которая здесь была переименована), обработчик события OnEvent просто вызывает :Show() для BagWatchFrame, что активирует OnUpdate. Как только пройдёт заданное время (в этом случае 0.5 секунды), произойдёт сканирование сумок. Это означает, что даже если произойдёт несколько BAG_UPDATE событий подряд, сработает только одна проверка — после установленной задержки.
  
📘 Повторяющийся код с помощью OnUpdate

  Скрипты OnUpdate можно также использовать для периодического запуска кода. Например, ты можешь изменить аддон CombatTracker, созданный в главе 14, так, чтобы он обновлял интерфейс каждую секунду во время боя — вместо того чтобы показывать информацию только в конце боя.
  
  Добавь следующую функцию в конец файла CombatTracker.lua:
    local throttle = 1.0
    local counter = 0

    function CombatTracker_OnUpdate(self, elapsed)
      counter = counter + elapsed
      if counter >= throttle then
        CombatTracker_UpdateText()
        counter = 0
      end
    end
    
  Затем нужно установить обработчик OnUpdate при входе в бой и убрать его при выходе из боя.
  В обработчике CombatTracker_OnEvent():
  
  В блоке PLAYER_REGEN_ENABLED добавь строку:
    frame:SetScript("OnUpdate", nil)
    
  В блоке PLAYER_REGEN_DISABLED добавь:
    frame:SetScript("OnUpdate", CombatTracker_OnUpdate)
    
  Теперь, пока ты находишься в бою, обновление расчётов будет происходить каждую секунду.

📘 Производительность и OnUpdate-скрипты

  Помни, что код в обработчике OnUpdate вызывается на каждый кадр.
  Если у тебя, например, 60 кадров в секунду, значит, скрипт будет выполняться 60 раз в секунду. Поэтому важно учитывать производительность при написании таких функций. Не нужно паниковать и микроменеджерить каждую строчку, но плохая реализация OnUpdate может повлиять на FPS.

  Особенно стоит помнить следующее:
    Клиент игры выполняет код последовательно, и все OnUpdate-функции отрабатываются до обработки событий и отрисовки графики.

    Если нет нужды в выполнении кода каждый кадр, используй ограничение по времени (throttle) — как в примере выше.

    Локальные переменные работают быстрее, чем глобальные, так что это может немного повысить производительность.

📘 Итог
  В этой главе ты узнал, как использовать OnUpdate для создания задержек или периодического выполнения кода.
  Были созданы небольшие аддоны, использующие OnUpdate для различных задач.
  
  В следующей главе ты узнаешь о перехвате функций (hooking) и комбинировании таймера OnUpdate с перехватом, чтобы модифицировать интерфейс игры.
    
    