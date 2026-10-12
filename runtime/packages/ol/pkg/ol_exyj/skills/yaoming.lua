local yaoming = fk.CreateSkill {
  name = "ol_ex__yaoming",
}

Fk:loadTranslationTable {
  ["ol_ex__yaoming"] = "邀名",
  [":ol_ex__yaoming"] = "每回合限一次，当你造成或受到伤害后，你可以选择一名角色，若其手牌数：" ..
  "大于等于你，你弃置其一张牌；小于等于你，其摸一张牌。然后其回合内，你发动〖赈赡〗无次数限制。",

  ["@[list]ol_ex__yaoming"] = "邀名",
  ["#ol_ex__yaoming-choose"] = "邀名：选择一名角色，其手牌数大于等于你则弃置其一张牌，小于等于你则其摸一张牌",

  ["$ol_ex__yaoming1"] = "",
  ["$ol_ex__yaoming2"] = "",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yaoming.name) and
      player:usedSkillTimes(yaoming.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__yaoming-choose",
      skill_name = yaoming.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local yes1 = to:getHandcardNum() >= player:getHandcardNum() and not to:isNude()
    local yes2 = to:getHandcardNum() <= player:getHandcardNum()
    if yes1 then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = yaoming.name,
      })
      room:throwCard(id, yaoming.name, to, player)
    end
    if yes2 and not to.dead then
      to:drawCards(1, yaoming.name)
    end
    if player:hasSkill(yaoming.name, true) then
      room:addTableMarkIfNeed(player, "@[list]ol_ex__yaoming", to)
    end
  end,
}
yaoming:addEffect(fk.Damage, spec)
yaoming:addEffect(fk.Damaged, spec)

yaoming:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[list]ol_ex__yaoming", 0)
end)

return yaoming
