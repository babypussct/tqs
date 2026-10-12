
local neirao = fk.CreateSkill {
  name = "os__neirao",
  tags = { Skill.Wake },
  related_skills = { "os__luanlue" },
}

Fk:loadTranslationTable{
  ["os__neirao"] = "内扰",
  [":os__neirao"] = "觉醒技，准备阶段，若你的体力值与体力上限之和不大于9，你失去〖竭匡〗，" ..
  "弃置全部牌并从牌堆或弃牌堆中获得等量的【杀】，然后获得技能〖乱掠〗。",

  ["$os__neirao1"] = "家破父亡，请留汉土。",
  ["$os__neirao2"] = "虚国匡汉，无力安家。",
}

neirao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(neirao.name) and player.phase == Player.Start and
      player:usedSkillTimes(neirao.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp + player.maxHp < 10
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-os__jiekuang")
    local num = #player:getCardIds("he")
    player:throwAllCards("he", neirao.name)
    if player.dead then return end
    room:obtainCard(player, room:getCardsFromPileByRule("slash", num, "allPiles"), false, fk.ReasonPrey, player, neirao.name)
    if player.dead then return end
    room:handleAddLoseSkills(player, "os__luanlue")
  end,
})

return neirao
