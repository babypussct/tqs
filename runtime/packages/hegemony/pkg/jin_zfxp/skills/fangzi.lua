
local fangzi = fk.CreateSkill {
  name = "heg__fangzi",
}

Fk:loadTranslationTable {
  ["heg__fangzi"] = "放恣",
  [":heg__fangzi"] = "结束阶段，你可以变更副将并获得与被变更的副将势力相同的所有角色各一张手牌。",

  ["#heg__fangzi-invoke"] = "放恣：你可以变更副将，获得被变更势力所有角色各一张手牌",
}

local H = require "packages.hegemony.util"

fangzi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangzi.name) and player.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fangzi.name,
      prompt = "#heg__fangzi-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local kingdom = Fk.generals[H.getActualGeneral(player, true)].kingdom
    H.transformGeneral(room, player, false, true)
    if player.dead then return end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if H.getKingdom(p) == kingdom and not p:isKongcheng() then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = fangzi.name,
        })
        room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, fangzi.name, nil, false, player)
        if player.dead then return end
      end
    end
  end,
})

return fangzi
