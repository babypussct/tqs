local jieming = fk.CreateSkill({
  name = "m_ex__jieming",
})

Fk:loadTranslationTable{
  ["m_ex__jieming"] = "节命",
  [":m_ex__jieming"] = "当你受到1点伤害后，你可以令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌。",

  ["#m_ex__jieming-choose"] = "节命：令一名角色摸两张牌，然后若其手牌数小于体力上限，你摸一张牌",

  ["$m_ex__jieming1"] = "因势利导，是为良计。",
  ["$m_ex__jieming2"] = "杀身成仁，不负皇恩。",
}

jieming:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = jieming.name,
      prompt = "#m_ex__jieming-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:drawCards(2, jieming.name)
    if to:getHandcardNum() < to.maxHp and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
})

return jieming
