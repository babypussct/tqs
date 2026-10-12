
local lie = fk.CreateSkill {
  name = "mobile__natu_lie",
}

Fk:loadTranslationTable {
  ["mobile__natu_lie"] = "烈",
  [":mobile__natu_lie"] = "你使用基本牌后，你可以将手牌数调整至X张（X为本回合发动此技能次数+1，且至多为5），"..
  "若你因此弃置了牌，你可以对一名角色造成1点伤害。",

  ["#mobile__natu_lie-invoke"] = "烈：你可以将手牌数调整至%arg张，若因此弃置牌，可以造成1点伤害",
  ["#mobile__natu_lie-damage"] = "烈：你可以对一名角色造成1点伤害",

  ["$mobile__natu_lie1"] = "奉劝亲们一句，还是闪开点好。",
  ["$mobile__natu_lie2"] = "想打败我，亲们还是一起上吧。",
}

lie:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lie.name) and
      data.card.type == Card.TypeBasic
  end,
  on_cost = function (self, event, target, player, data)
    local n = player:usedSkillTimes(lie.name, Player.HistoryTurn) + 1
    n = math.min(n, 5)
    return player.room:askToSkillInvoke(player, {
      skill_name = lie.name,
      prompt = "#mobile__natu_lie-invoke:::"..n,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:usedSkillTimes(lie.name, Player.HistoryTurn)
    n = player:getHandcardNum() - math.min(n, 5)
    if n < 0 then
      player:drawCards(-n, lie.name)
    elseif n > 0 then
      if #room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        skill_name = lie.name,
        cancelable = false,
        include_equip = false,
      }) > 0 and not player.dead then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = "#mobile__natu_lie-damage",
          skill_name = lie.name,
        })
        if #to > 0 then
          room:damage{
            from = player,
            to = to[1],
            damage = 1,
            skillName = lie.name,
          }
        end
      end
    end
  end,
})

return lie
