local zunhou = fk.CreateSkill {
  name = "zunhou",
  tags = { Skill.Compulsory },
  derived_piles = "zunhou",
}

Fk:loadTranslationTable{
  ["zunhou"] = "尊后",
  [":zunhou"] = "锁定技，当你成为牌的目标时，若没有与此牌点数相同的“尊后”，你从牌堆底将一张此点数的牌置于武将牌上（称为“尊后”），"..
    "当你受到伤害时或你的回合结束时，你将所有“尊后”交给一名角色。",

  ["#zunhou-choose"] = "尊后：将所有“尊后”牌交给一名角色",

  ["$zunhou1"] = "",
  ["$zunhou2"] = "",
}

zunhou:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if data.to == player and player:hasSkill(zunhou.name) and not data.cancelled then
      local n = data.card.number
      return n ~= 0 and table.every(player:getPile(zunhou.name), function(id)
        return n ~= Fk:getCardById(id).number
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.card.number
    local drawPile = room.draw_pile
    for i = #drawPile, 1, -1 do
      local id = drawPile[i]
      if Fk:getCardById(id).number == n then
        player:addToPile(zunhou.name, id, true, zunhou.name, player)
        break
      end
    end
  end,
})

---@type TrigSkelSpec<TrigFunc>
local spec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zunhou.name) and #player:getPile(zunhou.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = zunhou.name
    local cards = player:getPile(zunhou.name)
    if #cards == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = skillName,
      prompt = "#zunhou-choose",
      cancelable = false,
    })
    if #tos == 0 then return end
    room:obtainCard(tos[1], cards, true, fk.ReasonGive, player, skillName)
  end,
}

zunhou:addEffect(fk.DetermineDamageInflicted, spec)
zunhou:addEffect(fk.TurnEnd, spec)

return zunhou
