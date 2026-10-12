local yueyuan = fk.CreateSkill {
  name = "yueyuan",
}

Fk:loadTranslationTable{
  ["yueyuan"] = "跃渊",
  [":yueyuan"] = "出牌阶段限一次，你可以摸X张牌（X为你的“藏铗”记录的花色数），然后清除你的“藏铗”记录的一个花色。",

  ["#yueyuan-active"] = "跃渊：你可摸%arg张牌，然后清除你的“藏铗”记录的一个花色",
  ["#yueyuan-remove"] = "跃渊：你选择并清除你的“藏铗”记录的一个花色",

  ["$yueyuan1"] = "凤非梧不栖，士非主不依。",
  ["$yueyuan2"] = "刘璋暗弱，士民不附，此将军之机也。",
}

yueyuan:addEffect("active", {
  prompt = function(self, player)
    return "#yueyuan-active:::" .. #player:getTableMark("@cangjia_record")
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return
      player:usedSkillTimes(yueyuan.name, Player.HistoryPhase) == 0 and
      #player:getTableMark("@cangjia_record") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(#player:getTableMark("@cangjia_record"), yueyuan.name)
    if not player:isAlive() then
      return false
    end

    local cangjiaRecord = player:getTableMark("@cangjia_record")
    local choice = room:askToChoice(
      player,
      {
        choices = cangjiaRecord,
        skill_name = yueyuan.name,
        prompt = "#yueyuan-remove",
      }
    )

    room:removeTableMark(player, "@cangjia_record", choice)
  end,
})

return yueyuan
