local qizhou = fk.CreateSkill{
  name = "mobile__qizhou",
  tags = { Skill.Compulsory },
  related_skills = { "yingzi", "qixi", "xuanfeng" },
}

Fk:loadTranslationTable{
  ["mobile__qizhou"] = "绮胄",
  [":mobile__qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-〖英姿〗；2种以上-〖奇袭〗；3种以上-〖旋风〗。",

  ["$yingzi_mobile__heqi"] = "兵利革韧，他人如何不羡？",
  ["$qixi_mobile__heqi"] = "趁马引刃，击敌不备！",
  ["$xuanfeng_mobile__heqi"] = "奢绮之军，无惧敌犯！",
}

local function QizhouChange(player, num, skill_name)
  local room = player.room
  local skills = player.tag[qizhou.name] or {}
  local suits = {}
  for _, e in ipairs(player:getCardIds("e")) do
    table.insertIfNeed(suits, Fk:getCardById(e).suit)
  end
  table.removeOne(suits, Card.NoSuit)
  if #suits >= num then
    if not table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, skill_name, nil, false, true)
      table.insert(skills, skill_name)
    end
  else
    if table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, "-"..skill_name, nil, false, true)
      table.removeOne(skills, skill_name)
    end
  end
  player.tag[qizhou.name] = skills
end

qizhou:addEffect(fk.EventLoseSkill, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.skill.name == qizhou.name and #(player.tag[qizhou.name] or {}) > 0
  end,
  on_use = function (self, event, target, player, data)
    local skills = player.tag[qizhou.name]
    player.room:handleAddLoseSkills(player, "-"..table.concat(skills, "|"), nil, false, true)
    player.tag[qizhou.name] = nil
  end,
})
qizhou:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(qizhou.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerEquip then
          return true
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    QizhouChange(player, 1, "yingzi")
    QizhouChange(player, 2, "qixi")
    QizhouChange(player, 3, "xuanfeng")
  end,
})

return qizhou
