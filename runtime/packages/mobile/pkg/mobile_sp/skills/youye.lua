local youye = fk.CreateSkill {
  name = "youye",
  tags = { Skill.Compulsory },
  derived_piles = "poise",
}

Fk:loadTranslationTable{
  ["youye"] = "攸业",
  [":youye"] = "锁定技，其他角色的结束阶段，若其本回合未对你造成过伤害，你将牌堆顶的一张牌置于你的武将牌上，" ..
  "称为“蓄”（至多5张）。当你造成或受到伤害后，你任意分配所有“蓄”。",

  ["poise"] = "蓄",
  ["#youye-give"] = "攸业：任意分配所有“蓄”",

  ["$youye1"] = "筑城西疆，开万代太平。",
  ["$youye2"] = "镇边戍卫，许万民攸业。",
}

youye:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(youye.name) and target.phase == Player.Finish and
      #player:getPile("poise") < 5 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == target and e.data.to == player
      end) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addToPile("poise", room:getNCards(1), true, youye.name, player)
  end,
})

local spec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(youye.name) and #player:getPile("poise") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("poise")
    local result = room:askToYiji(player, {
      cards = cards,
      targets = room.alive_players,
      skill_name = youye.name,
      min_num = #cards,
      max_num = #cards,
      prompt = "#youye-give::"..room.current.id,
      expand_pile = "poise",
    })
    --if not player.dead and #result[room.current.id] == 0 then
    --  room:loseHp(player, 1, youye.name)
    --end
  end,
}
youye:addEffect(fk.Damage, spec)
youye:addEffect(fk.Damaged, spec)

return youye
