local tunchu = fk.CreateSkill{
  name = "ofl_heg__tunchu",
  derived_piles = "ofl_heg__lifeng_liang",
}

Fk:loadTranslationTable{
  ["ofl_heg__tunchu"] = "屯储",
  [":ofl_heg__tunchu"] = "摸牌阶段，你可以多摸两张牌，然后将至多两张手牌置于你的武将牌上，称为“粮”，若如此做，本回合你不能使用【杀】。",

  ["@@ofl_heg__tunchu_prohibit-turn"] = "屯储",
  ["#ofl_heg__tunchu-put"] = "屯储：你可以将至多两张手牌置为“粮”",

  ["$ofl_heg__tunchu1"] = "屯粮事大，暂不与尔等计较。",
  ["$ofl_heg__tunchu2"] = "屯粮待战，莫动刀枪。",
}

tunchu:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
    player.room:setPlayerMark(player, "@@ofl_heg__tunchu_prohibit-turn", 1)
  end,
})

tunchu:addEffect(fk.AfterDrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(tunchu.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = tunchu.name,
      prompt = "#ofl_heg__tunchu-put",
      cancelable = true,
    })
    if #cards > 0 then
      player:addToPile("ofl_heg__lifeng_liang", cards, true, tunchu.name)
    end
  end,
})

tunchu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("@@ofl_heg__tunchu_prohibit-turn") > 0 and card.trueName == "slash"
  end,
})

return tunchu
