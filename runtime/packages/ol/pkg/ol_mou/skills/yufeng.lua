local yufeng = fk.CreateSkill{
  name = "yufeng",
}

Fk:loadTranslationTable{
  ["yufeng"] = "玉锋",
  [":yufeng"] = "游戏开始时，将【思召剑】置入你的装备区。",

  ["$yufeng1"] = "梦神人授剑，怀神兵济世。",
  ["$yufeng2"] = "士者怎可徒手而战？",
  ["$yufeng3"] = "哼！我剑也未尝不利！",
}

yufeng:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yufeng.name) then return false end
    local room = player.room
    return player:hasEmptyEquipSlot(Card.SubtypeWeapon) and
      room:getCardArea(room:prepareDeriveCards({{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards")[1]) == Card.Void
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardIntoEquip(player, room:prepareDeriveCards({{"sizhao_sword", Card.Diamond, 6}}, "yufeng_derivecards"), yufeng.name)
  end,
})

return yufeng
