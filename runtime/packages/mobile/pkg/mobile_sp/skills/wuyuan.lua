local wuyuan = fk.CreateSkill {
  name = "wuyuan",
}

Fk:loadTranslationTable{
  ["wuyuan"] = "武缘",
  [":wuyuan"] = "出牌阶段限一次，你可以交给一名其他角色一张【杀】，然后你回复1点体力，其摸一张牌。若此【杀】为：红色【杀】，该角色额外回复1点体力；"..
  "非普通【杀】，该角色额外摸一张牌。",

  ["$wuyuan1"] = "夫君，此次出征，还望您记挂妾身！",
  ["$wuyuan2"] = "云长，一定要平安归来啊！",
}

wuyuan:addEffect("active", {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(wuyuan.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = wuyuan.name
    local player = effect.from
    local target = effect.tos[1]
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, false, fk.ReasonGive, player, skillName)
    if player:isAlive() and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      })
    end
    if target:isAlive() then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = skillName,
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, skillName)
    end
  end,
})

return wuyuan
