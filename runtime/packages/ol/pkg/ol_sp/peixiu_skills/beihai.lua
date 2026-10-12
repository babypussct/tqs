local beihai = fk.CreateSkill {
  name = "peixiu_beihai",
}

Fk:loadTranslationTable {
  ["peixiu_beihai"] = "北海",
  [":peixiu_beihai"] = "你获得此技能后，将手牌摸至体力上限。",
}

beihai:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(beihai.name) and data.skill.name == beihai.name and
      player.maxHp > player:getHandcardNum()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), beihai.name)
  end
})

return beihai
