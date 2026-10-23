
local cunsi = fk.CreateSkill{
  name = "cunsi",
  related_skills = { "yongjue" },
}
local H = require "packages.hegemony.util"
cunsi:addEffect("active", {
  anim_type = "big",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  --[[
  can_use = function (self, player)
    
  end,
  --]]
  on_use = function(self, room, effect)
    local player = effect.from
    local isDeputy = H.inGeneralSkills(player, cunsi.name)
    if isDeputy then
      H.removeGeneral(player, isDeputy == "d")
    end
    local target = effect.tos[1]
    room:handleAddLoseSkills(target, "yongjue", nil)
    if target ~= player and not target.dead then
      target:drawCards(2, cunsi.name)
    end
  end,
})

-- Yongjue only pays off for a same-kingdom recipient.  An allied recipient
-- also receives the two-card grant, so prefer a living ally with a larger
-- public hand over sacrificing the skill onto an enemy; use self only as a
-- safe fallback when no ally is available.
cunsi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local best, best_value
    for _, target in ipairs(ai:getEnabledTargets()) do
      local value
      if target == player then
        value = 40
      else
        local relation = ai:getFactionRelation(target)
        if relation and relation.state == "friend" and
            (type(target.isAlive) ~= "function" or target:isAlive()) then
          local hand_num = type(target.getHandcardNum) == "function" and target:getHandcardNum() or 0
          value = 78 + math.min(hand_num, 5) * 8
          if type(target.hasSkill) == "function" and target:hasSkill("yongjue") then
            value = value - 25
          end
        end
      end
      if value and (not best or value > best_value or (value == best_value and target.id < best.id)) then
        best, best_value = target, value
      end
    end
    if best then
      return { {}, { best } }, best_value
    end
  end,
})

Fk:loadTranslationTable{
  ["cunsi"] = "存嗣",
  [":cunsi"] = "出牌阶段，你可移除此武将牌并选择一名角色，其获得〖勇决〗。若其不为你，其摸两张牌。", -- canShowInPlay 若此武将牌处于明置状态

  ["$cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$cunsi2"] = "一切，便托付将军了……",
}

return cunsi
