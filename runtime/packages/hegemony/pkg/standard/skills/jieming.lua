
local jieming = fk.CreateSkill{
  name = "hs__jieming",
}

Fk:loadTranslationTable{
  ["hs__jieming"] = "节命",
  [":hs__jieming"] = "当你受到伤害后，你可以令一名角色将手牌补至X张（X为其体力上限且最多为5）。",

  ["$hs__jieming1"] = "秉忠贞之志，守谦退之节。",
  ["$hs__jieming2"] = "我，永不背弃。",
}

jieming:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = jieming.name,
      prompt = "#jieming-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local num = math.min(to.maxHp, 5) - to:getHandcardNum()
    if num > 0 then
      to:drawCards(num, jieming.name)
    end
  end,
})

local AI = Fk.Ltk.AI
jieming:addAI(AI.reuse("jieming", AI.ChoosePlayersStrategy))

return jieming
