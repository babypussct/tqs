local xingshang = fk.CreateSkill{
  name = "m_ex__xingshang",
}

Fk:loadTranslationTable{
  ["m_ex__xingshang"] = "行殇",
  [":m_ex__xingshang"] = "当其他角色死亡时，你可以选择一项：1.获得其所有牌；2.回复1点体力。",

  ["m_ex__xingshang_prey"] = "获得%dest的所有牌",

  ["$m_ex__xingshang1"] = "群燕辞归鹄南翔，念君客游思断肠。",
  ["$m_ex__xingshang2"] = "霜露纷兮交下，木叶落兮凄凄。",
}

xingshang:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xingshang.name) and (not target:isNude() or player:isWounded())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }
    if player:isWounded() then
      table.insert(choices, 1, "recover")
    end
    if not target:isNude() then
      table.insert(choices, 1, "m_ex__xingshang_prey::"..target.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xingshang.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = choice ~= "recover" and {target} or nil, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "recover" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = xingshang.name,
      }
    else
      room:obtainCard(player, target:getCardIds("he"), false, fk.ReasonPrey, player, xingshang.name)
    end
  end,
})

return xingshang
