local zhaoxin = fk.CreateSkill {
  name = "ld__zhaoxin",
}

Fk:loadTranslationTable {
  ["ld__zhaoxin"] = "昭心",
  [":ld__zhaoxin"] = "当你受到伤害后，你可展示所有手牌，然后与一名手牌数不大于你的角色交换手牌。",
  ["#ld__zhaoxin-ask"] = "昭心：你可以展示所有手牌，然后与一名手牌数不大于你的角色交换手牌",
  ["#ld__zhaoxin-choose"] = "昭心：选择一名手牌数不大于你的角色，与其交换手牌",

  ["$ld__zhaoxin1"] = "行明动正，何惧他人讥毁。",
  ["$ld__zhaoxin2"] = "大业之举，岂因宵小而动？",
}

zhaoxin:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhaoxin.name) and player == target and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = zhaoxin.name, prompt = "#ld__zhaoxin-ask" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player.player_cards[Player.Hand])
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return (p:getHandcardNum() <= player:getHandcardNum())
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ld__zhaoxin-choose",
        skill_name = zhaoxin.name,
        cancelable = false,
      })[1]
      room:swapAllCards(player, { player, to }, zhaoxin.name, "h")
    end
  end,
})

return zhaoxin
