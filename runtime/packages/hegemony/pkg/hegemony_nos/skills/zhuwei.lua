
local zhuwei = fk.CreateSkill{
  name = "nos_heg__zhuwei",
}

Fk:loadTranslationTable{
  ["nos_heg__zhuwei"] = "筑围",
  [":nos_heg__zhuwei"] = "当你的判定结果确定后，若为【杀】或伤害类锦囊牌，你可以获得之，"..
  "然后你可以令当前回合角色本回合使用【杀】的次数上限+1、手牌上限+1。",

  ["#nos_heg__zhuwei-invoke"] = "筑围：是否令 %dest 本回合使用【杀】次数和手牌上限+1？",

  ["$nos_heg__zhuwei1"] = "背水一战，只为破敌。",
  ["$nos_heg__zhuwei2"] = "全线并进，连战克晋。",
}

zhuwei:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuwei.name) and
      data.card and data.card.is_damage_card and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, zhuwei.name, nil, true, player)
    local current = room:getCurrent()
    if player.dead or current == nil or current.dead then return end
    if room:askToSkillInvoke(player, {
      skill_name = zhuwei.name,
      prompt = "#nos_heg__zhuwei-invoke::"..current.id,
    }) then
      room:addPlayerMark(current, MarkEnum.SlashResidue.."-turn", 1)
      room:addPlayerMark(current, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
})

return zhuwei
