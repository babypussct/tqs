local guanhuo = fk.CreateSkill{
  name = "os_js__guanhuo",
}

Fk:loadTranslationTable{
  ["os_js__guanhuo"] = "观火",
  [":os_js__guanhuo"] = "出牌阶段，你可以视为使用一张【火攻】，" ..
    "当此牌结算结束后，若此牌未造成伤害且你于此阶段：第一次发动〖观火〗，此阶段你使用【火攻】造成的伤害+1；" ..
    "不为第一次发动〖观火〗，你失去〖观火〗。",

  ["#os_js__guanhuo"] = "观火：你可以视为使用一张【火攻】",
  ["@@os_js__guanhuo-phase"] = "观火",

  ["$os_js__guanhuo1"] = "四面合围，纵火惊之，此战必剿黄巾残党！",
  ["$os_js__guanhuo2"] = "兵有奇变，不在众寡，当以计胜之！",
}

guanhuo:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#os_js__guanhuo",
  card_filter = Util.FalseFunc,
  view_as = function (self, player, cards)
    local card = Fk:cloneCard("fire_attack")
    card.skillName = guanhuo.name
    return card
  end,
  after_use = function (self, player, use)
    if not player.dead and not use.damageDealt then
      local room = player.room
      if player:usedEffectTimes(self.name, Player.HistoryPhase) == 1 then
        room:addPlayerMark(player, "@@os_js__guanhuo-phase", 1)
      else
        room:handleAddLoseSkills(player, "-os_js__guanhuo")
      end
    end
  end,
})

guanhuo:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@os_js__guanhuo-phase") > 0 and data.card.trueName == "fire_attack"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return guanhuo
