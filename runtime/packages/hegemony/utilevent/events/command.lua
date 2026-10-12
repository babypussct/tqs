---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"

---@class HegUtil.GameEvent.Command : GameEvent
---@field public data HegUtil.CommandData
local Command = GameEvent:subclass("HegUtil.GameEvent.Command")

function Command:__tostring()
  local data = self.data
  local command = data.command or "nil"
  if data.forced then
    command = command .. "(forced)"
  end
  return string.format("<Command %s : %s <= %s[%s] #%d>",
    command, data.tos, data.from, data.skillName, self.id)
end

function Command:prepare()
  local commandData = self.data
  local room = self.room

  local from = commandData.from
  if from.dead then
    return true
  end

  if not commandData.command then
    commandData.command = HegUtil.askToStartCommand(from, {
      num = commandData.num,
      pool = commandData.pool,
      skill_name = commandData.skillName,
      no_log = commandData.no_log,
    })

    if not commandData.command then
      return true
    end
  end

  room:sortByAction(commandData.tos)

  commandData.forced_list = commandData.forced_list or {}
  if commandData.forced then
    for _, to in ipairs(commandData.tos) do
      table.insertIfNeed(commandData.forced_list, to)
    end
  end
  commandData.succeed_list = commandData.succeed_list or {}
end

function Command:main()
  local commandData = self.data
  local room = self.room
  local logic = room.logic
  local tos = commandData.tos
  local from = commandData.from

  HegUtil.CommandPrepare(commandData.command, commandData)
  if not commandData.no_indicate then
    room:doIndicate(from.id, tos)
  end
  for _, to in ipairs(tos) do
    if from.dead or not commandData.command then
      logic:breakEvent(false)
    end
    if to:isAlive() then
      local choice = room:askToChoice(to, {
        choices = { commandData.command },
        skill_name = "do_command",
        detailed = true,
        cancelable = not table.contains(commandData.forced_list, to),
      })

      commandData.succeed = choice ~= "Cancel"
      local result = commandData.succeed and "#commandselect_yes" or "#commandselect_no"
      room:sendLog{
        type = "#CommandChoice",
        from = to.id,
        arg = result,
      }
      --[[ -- 酷炫顶栏
      local ret = "<b><font color='#CC3131'>" .. Fk:translate(to.general)
      if to.deputyGeneral and to.deputyGeneral ~= "" then
        ret = ret .. "/" .. Fk:translate(to.deputyGeneral)
      end
      ret = ret .. "</b></font> " .. Fk:translate("chose") .. " <b>" .. Fk:translate(result) .. "</b>"
      room:doBroadcastNotify("ServerMessage", ret)
      --]]
      if commandData.succeed and not room.logic:trigger(HegUtil.CommandExecuting, to, commandData) then
        commandData.succeed = true
        table.insert(commandData.succeed_list, to)
        HegUtil.CommandCB(commandData.command, to, commandData.from, commandData)
      end
      room.logic:trigger(HegUtil.CommandExecuted, to, commandData)
    end
  end
end

-- function Command:exit()
--   local commandData = self.data
--   local room = self.room
-- end

return Command
