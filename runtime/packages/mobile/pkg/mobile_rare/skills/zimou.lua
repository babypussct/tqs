local zimou = fk.CreateSkill {
  name = "changshi__zimou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["changshi__zimou"] = "自谋",
  [":changshi__zimou"] = "锁定技，当你于出牌阶段内使用：第二张牌时，你随机获得一张【酒】；第四张牌时，你随机获得一张【杀】；第六张牌时，"..
  "你随机获得一张【决斗】。",

  ["@changshi__zimou"] = "自谋",

  ["$changshi__zimou1"] = "在宫里当差，还不是为这利字！",
}

zimou:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zimou.name) and
      player.phase == Player.Play and table.contains({ 2, 4, 6 }, player:getMark("@changshi__zimou"))
  end,
  on_use = function(self, event, target, player, data)
    local count = player:getMark("@changshi__zimou")
    local name = "analeptic"
    if count == 4 then
      name = "slash"
    elseif count == 6 then
      name = "duel"
    end
    local card = player.room:getCardsFromPileByRule(name)
    if #card > 0 then
      player.room:moveCards({
        ids = card,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = zimou.name,
      })
    end
  end,
})
zimou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zimou.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@changshi__zimou", 1)
  end,
})

return zimou
