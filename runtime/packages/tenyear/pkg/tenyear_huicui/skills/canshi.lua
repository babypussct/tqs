local canshi = fk.CreateSkill {
  name = "ty__canshi",
}

Fk:loadTranslationTable {
  ["ty__canshi"] = "残蚀",
  [":ty__canshi"] = "摸牌阶段，你可以额外摸X张牌(X为已受伤的角色数)，然后本回合你使用【杀】或普通锦囊牌时，弃置一张牌。",

  ["$ty__canshi1"] = "天地不仁，当视苍生为刍狗！",
  ["$ty__canshi2"] = "真龙天子，焉能不择人而噬！",
}

canshi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(canshi.name) and
        table.find(player.room.alive_players, function(p)
          return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
        end)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + #table.filter(player.room.alive_players, function(p)
      return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
})
canshi:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
        player:usedSkillTimes(canshi.name, Player.HistoryTurn) > 0 and
        not player:isNude() and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = canshi.name,
      cancelable = false,
    })
  end,
})

return canshi
