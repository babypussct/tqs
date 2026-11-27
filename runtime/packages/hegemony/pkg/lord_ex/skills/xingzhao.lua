
local xingzhao = fk.CreateSkill {
  name = "ld__xingzhao",
}

Fk:loadTranslationTable{
  ["ld__xingzhao"] = "兴棹",
  [":ld__xingzhao"] = "出牌阶段限一次，你可以对一名角色造成1点伤害，然后其可以弃置至多两张装备牌，摸两倍数量的牌。",

  ["#ld__xingzhao"] = "兴棹：对一名角色造成1点伤害，其可以弃置装备牌并摸两倍的牌",
  ["#ld__xingzhao-discard"] = "兴棹：你可以弃置至多两张装备牌，摸两倍的牌",

  ["$ld__xingzhao1"] = "精挑细选，方能成百年之计。",
  ["$ld__xingzhao2"] = "拿些上好的木料来。",
}

xingzhao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ld__xingzhao",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xingzhao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = xingzhao.name,
    }
    if target:isNude() then return end
    local n = #room:askToDiscard(target, {
      min_num = 1,
      max_num = 2,
      include_equip = true,
      skill_name = xingzhao.name,
      pattern = ".|.|.|.|.|equip",
      prompt = "#ld__xingzhao-discard",
      cancelable = true,
    })
    if n > 0 and not target.dead then
      target:drawCards(2 * n, xingzhao.name)
    end
  end,
})

return xingzhao
