local tunchu = fk.CreateSkill {
  name = "tunchu",
  derived_piles = "lifeng_liang",
}

Fk:loadTranslationTable{
  ["tunchu"] = "屯储",
  [":tunchu"] = "摸牌阶段，若你没有“粮”，你可以多摸两张牌，然后可以将任意张手牌置于你的武将牌上，称为“粮”；若你的武将牌上有“粮”，你不能使用【杀】。",

  ["lifeng_liang"] = "粮",
  ["#tunchu-put"] = "屯储：你可以将任意张手牌置为“粮”",

  ["$tunchu1"] = "屯粮事大，暂不与尔等计较。",
  ["$tunchu2"] = "屯粮待战，莫动刀枪。",
}

tunchu:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tunchu.name) and #player:getPile("lifeng_liang") == 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

tunchu:addEffect(fk.AfterDrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(tunchu.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = player:getHandcardNum(),
        skill_name = tunchu.name,
        prompt = "#tunchu-put",
      }
    )
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("lifeng_liang", event:getCostData(self).cards, true, tunchu.name)
  end,
})

tunchu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(tunchu.name) and #player:getPile("lifeng_liang") > 0 and card.trueName == "slash"
  end,
})

return tunchu
