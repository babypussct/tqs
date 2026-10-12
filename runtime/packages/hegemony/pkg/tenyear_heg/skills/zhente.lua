local zhente = fk.CreateSkill{
  name = "ty_heg__zhente",
}

Fk:loadTranslationTable{
  ["ty_heg__zhente"] = "贞特",
  [":ty_heg__zhente"] = "每回合限一次，当你成为其他角色使用黑色基本牌或黑色普通锦囊牌的目标后，你可以令使用者选择一项：1.本回合不能使用黑色牌；"..
  "2.此牌对你无效。",

  ["#ty_heg__zhente-invoke"] = "贞特：令 %src 选择【%arg】对你无效或不能再使用%arg2牌",
  ["ty_heg__zhente_negate"] = "令【%arg】对%dest无效",
  ["ty_heg__zhente_colorlimit"] = "本回合不能再使用%arg牌",
  ["@ty_heg__zhente-turn"] = "贞特",

  ["$ty_heg__zhente1"] = "抗声昭节，义形于色。",
  ["$ty_heg__zhente2"] = "少履贞特之行，三从四德。",
}

zhente:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhente.name) and player:usedSkillTimes(zhente.name) == 0 and data.from ~= player then
      return (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and data.card.color == Card.Black
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
        skill_name = zhente.name,
        prompt = "#ty_heg__zhente-invoke:" .. data.from.id .. "::" .. data.card:toLogString() .. ":" .. data.card:getColorString()
      }) then
      event:setCostData(self, {tos = {data.from} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.from
    local color = data.card:getColorString()
    local choice = room:askToChoice(to, {
      choices = {
        "ty_heg__zhente_negate::" .. tostring(player.id) .. ":" .. data.card.name,
        "ty_heg__zhente_colorlimit:::" .. color
      },
      skill_name = zhente.name,
    })
    if choice:startsWith("ty_heg__zhente_negate") then
      data.nullified = true
    else
      local colorsRecorded = type(to:getMark("@ty_heg__zhente-turn")) == "table" and to:getMark("@ty_heg__zhente-turn") or {}
      table.insertIfNeed(colorsRecorded, color)
      room:setPlayerMark(to, "@ty_heg__zhente-turn", colorsRecorded)
    end
  end,
})

zhente:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@ty_heg__zhente-turn")
    return type(mark) == "table" and table.contains(mark, card:getColorString())
  end,
})

return zhente
