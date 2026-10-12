local yueyuan = fk.CreateSkill {
  name = "os__yueyuan",
}

Fk:loadTranslationTable{
  ["os__yueyuan"] = "跃渊",
  [":os__yueyuan"] = "出牌阶段限四次，你可以摸X张牌（X为你的“藏铗”记录的花色数），然后清除你的“藏铗”记录的一个花色。",

  ["#os__yueyuan-active"] = "跃渊：你可摸%arg张牌，然后清除你的“藏铗”记录的一个花色",
  ["#os__yueyuan-remove"] = "跃渊：你选择并清除你的“藏铗”记录的一个花色",

  ["$os__yueyuan1"] = "凤非梧不栖，士非主不依。",
  ["$os__yueyuan2"] = "刘璋暗弱，士民不附，此将军之机也。",
}

yueyuan:addEffect("active", {
  prompt = function(self, player)
    return "#os__yueyuan-active:::" .. #player:getTableMark("@os__cangjia_record")
  end,
  times = function (self, player)
    return 4 - player:usedSkillTimes(yueyuan.name, Player.HistoryPhase)
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return
      player:usedSkillTimes(yueyuan.name, Player.HistoryPhase) < 4 and
      #player:getTableMark("@os__cangjia_record") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(#player:getTableMark("@os__cangjia_record"), yueyuan.name)
    if not player:isAlive() then
      return false
    end

    local cangjiaRecord = player:getTableMark("@os__cangjia_record")
    local choice = room:askToChoice(
      player,
      {
        choices = cangjiaRecord,
        skill_name = yueyuan.name,
        prompt = "#os__yueyuan-remove",
      }
    )

    room:removeTableMark(player, "@os__cangjia_record", choice)
  end,
})

return yueyuan
