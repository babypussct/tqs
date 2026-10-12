local qianchong = fk.CreateSkill {
  name = "qianchong",
  tags = { Skill.Compulsory },
  related_skills = { "weimu", "mingzhe" },
}

Fk:loadTranslationTable{
  ["qianchong"] = "谦冲",
  [":qianchong"] = "锁定技，如果你的装备区所有牌均为黑色，则你拥有〖帷幕〗；如果你装备区所有牌均为红色，则你拥有〖明哲〗。出牌阶段开始时，"..
  "若你不满足上述条件，则你选择一种类型的牌，本阶段内使用此类型的牌无次数和距离限制。",

  ["#qianchong-choice"] = "谦冲：选择一种类别，此阶段内使用此类别的牌无次数和距离限制",
  ["@qianchong-phase"] = "谦冲",

  ["$qianchong1"] = "细行策划，只盼能助夫君一臂之力。",
}

qianchong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qianchong.name) and player.phase == Player.Play then
      local colors = {}
      for _, id in ipairs(player:getCardIds("e")) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      return #colors ~= 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askToChoice(
      player,
      {
        choices = { "basic", "trick", "equip" },
        skill_name = qianchong.name,
        prompt = "#qianchong-choice",
      }
    )
    player.room:setPlayerMark(player, "@qianchong-phase", choice)
  end,
})

qianchong:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
})

local qianchongHandleSkills = function(self, player)
  local room = player.room
  local equips = player:getCardIds("e")
  local hasweimu = player:hasSkill(qianchong.name, true, true) and #equips > 0 and table.every(equips, function (id)
    return Fk:getCardById(id).color == Card.Black
  end)
  local hasmingzhe = player:hasSkill(qianchong.name, true, true) and #equips > 0 and table.every(equips, function (id)
    return Fk:getCardById(id).color == Card.Red
  end)

  local qianchong_skills = player:getTableMark("qianchong_skills")
  local skillchange = {}
  if hasweimu and not player:hasSkill("weimu", true, true) then
    table.insert(skillchange, "weimu")
    table.insertIfNeed(qianchong_skills, "weimu")
  elseif not hasweimu and player:hasSkill("weimu", true, true) and table.contains(qianchong_skills, "weimu") then
    table.insert(skillchange, "-weimu")
    table.removeOne(qianchong_skills, "mingzhe")
  end
  if hasmingzhe and not player:hasSkill("mingzhe", true, true) then
    table.insert(skillchange, "mingzhe")
    table.insertIfNeed(qianchong_skills, "mingzhe")
  elseif not hasmingzhe and player:hasSkill("mingzhe", true, true) and table.contains(qianchong_skills, "mingzhe") then
    table.insert(skillchange, "-mingzhe")
    table.removeOne(qianchong_skills, "mingzhe")
  end
  if #skillchange > 0 then
    room:handleAddLoseSkills(player, table.concat(skillchange, "|"), nil, true, false)
    room:setPlayerMark(player, "qianchong_skills", qianchong_skills)
  end
end

qianchong:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    qianchongHandleSkills(self, player)
  end,
})

qianchong:addAcquireEffect(qianchongHandleSkills)

qianchong:addLoseEffect(qianchongHandleSkills)

return qianchong
