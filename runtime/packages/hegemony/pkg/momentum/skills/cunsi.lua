
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

Fk:loadTranslationTable{
  ["cunsi"] = "存嗣",
  [":cunsi"] = "出牌阶段，你可移除此武将牌并选择一名角色，其获得〖勇决〗。若其不为你，其摸两张牌。", -- canShowInPlay 若此武将牌处于明置状态

  ["$cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$cunsi2"] = "一切，便托付将军了……",
}

return cunsi
