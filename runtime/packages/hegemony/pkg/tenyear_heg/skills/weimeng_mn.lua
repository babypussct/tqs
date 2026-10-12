local weimeng = fk.CreateSkill{
  name = "ty_heg__weimeng_manoeuvre",
}

Fk:loadTranslationTable{
  ["ty_heg__weimeng_manoeuvre"] = "危盟⇋",
  [":ty_heg__weimeng_manoeuvre"] = "出牌阶段限一次，你可以获得目标角色一张手牌，然后交给其等量的牌。",

  ["#ty_heg__weimeng_manoeuvre"] = "危盟：获得一名其他角色一张牌，然后交给其一张牌",
}

weimeng:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_heg__weimeng_manoeuvre",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(weimeng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card1 = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = weimeng.name,
    })
    room:obtainCard(player, card1, false, fk.ReasonPrey)
    if player.dead or player:isNude() or target.dead then return end
    local card2 = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = weimeng.name,
      prompt = "#ty_heg__weimeng-give::"..target.id..":1",
      cancelable = false,
    })
    room:obtainCard(target, card2, false, fk.ReasonGive)
  end,
})

weimeng:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_heg__weimeng_manoeuvre", true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-ty_heg__weimeng_manoeuvre", nil)
    room:setPlayerMark(player, "@@ty_heg__weimeng_manoeuvre", 0)
  end,
})

return weimeng
