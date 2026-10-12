
local fubi = fk.CreateSkill {
  name = "fubi",
}

Fk:loadTranslationTable{
  ["fubi"] = "辅弼",
  [":fubi"] = "出牌阶段限一次，你可以选择一名角色并选择一项：1.令其获得一个其未拥有的“定仪”效果；"..
  "2.令其全部“定仪”效果翻倍直到你的下个出牌阶段开始。",

  ["#fubi"] = "辅弼：令一名角色获得一个其未拥有的“定仪”效果，或“定仪”效果加倍",
  ["fubi_double"] = "定仪效果翻倍",

  ["$fubi1"] = "辅君弼主，士之所志也。",
  ["$fubi2"] = "献策思计，佐定江山。",
}

fubi:addEffect("active", {
  anim_type = "support",
  prompt = "#fubi",
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "@@dingyi1", "@@dingyi2", "@@dingyi3", "@@dingyi4", "fubi_double" } },
  can_use = function (self, player)
    return player:usedSkillTimes(fubi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "fubi_double" then
        return table.find({ 1, 2, 3, 4 }, function (i)
          return to_select:getMark("@@dingyi"..i) > 0
        end)
      else
        return to_select:getMark(self.interaction.data) == 0
      end
    end
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if self.interaction.data == "fubi_double" then
      room:addPlayerMark(target, fubi.name, 1)
      room:addTableMark(player, "fubi_targets", target)
    else
      room:setPlayerMark(target, self.interaction.data, 1)
    end
  end,
})

fubi:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("fubi_targets") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player:getTableMark("fubi_targets")) do
      room:removePlayerMark(p, "fubi", 1)
    end
    room:setPlayerMark(player, "fubi_targets", 0)
  end,
})

return fubi
