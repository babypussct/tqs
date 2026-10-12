local osGongge = fk.CreateSkill {
  name = "os__gongge"
}

Fk:loadTranslationTable{
  ["os__gongge"] = "攻阁",
  [":os__gongge"] = "每回合限一次，当你使用伤害类的牌指定目标后，你可选择一项：1. 摸X+1张牌，若此牌被其响应，你跳过下次摸牌阶段；" ..
  "2. 弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌；3. 此牌对其伤害值基数+X，此牌结算后其回复X点体力。（X为其武将技能数）",

  ["os__gongge_draw"] = "摸%arg张牌",
  ["os__gongge_damage"] = "对%src伤害+%arg",
  ["os__gongge_discard"] = "弃置%src%arg张牌",
  ["#os__gongge-choice"] = "你想对 %dest 发动技能“攻阁”吗？",
  ["@os__gongge"] = "攻阁",
  ["os__gonggeDraw"] = "摸牌",
  ["os__gonggeDiscard"] = "弃牌",
  ["os__gonggeDamage"] = "加伤",
  ["@@os__gongge_skip"] = "攻阁跳摸牌",
  ["#os__gongge-cards"] = "攻阁：交给 %dest %arg张牌",

  ["$os__gongge1"] = "弓弩并射难近其身，若退又恐难安己命！",
  ["$os__gongge2"] = "既已决心反之，当速擒吕布以溃其兵士！",
  ["$os__gongge3"] = "今行至如此，唯殊死一搏！",
}

---@param player Player
local function getTrueSkills(player)
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if s:isPlayerSkill(player) then
      table.insertIfNeed(skills, s.name)
    end
  end
  return skills
end

-- 主技能
osGongge:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osGongge.name) and
      player:usedSkillTimes(osGongge.name) < 1 and
      data.card.is_damage_card and
      data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    local x = #getTrueSkills(to)
    local choices = { "os__gongge_draw:::" .. x + 1, "os__gongge_damage:" .. data.to.id ..  "::" .. x, "Cancel" }
    if #to:getCardIds("he") > x then
      table.insert(choices, 2, "os__gongge_discard:" .. data.to.id .. "::" .. x + 1)
    end
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osGongge.name,
        prompt = "#os__gongge-choice::" .. data.to.id,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osGongge.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "offensive")
    data.extra_data = data.extra_data or {}
    data.extra_data.os__gonggeTarget = data.to.id
    data.extra_data.os__gonggeUser = player.id

    local to = data.to
    room:doIndicate(player, { to })
    local choice = event:getCostData(self)
    local x = #getTrueSkills(to)
    if choice:startsWith("os__gongge_draw") then
      player:broadcastSkillInvoke(skillName, 1)
      player:drawCards(x + 1, skillName)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDraw")
    elseif choice:startsWith("os__gongge_discard") then
      player:broadcastSkillInvoke(skillName, 2)
      local cards = room:askToChooseCards(
        player,
        {
          min = x + 1,
          max = x + 1,
          target = to,
          flag = "he",
          skill_name = skillName,
        }
      )
      room:throwCard(cards, skillName, to, player)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDiscard")
    elseif choice:startsWith("os__gongge_damage") then
      player:broadcastSkillInvoke(skillName, 3)
      data.additionalDamage = (data.additionalDamage or 0) + x
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDamage")
    end
  end,
})

-- 判断技能
osGongge:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (data.extra_data or {}).os__gonggeUser == player.id and
      player:getMark("@os__gongge") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osGongge.name
    local room = player.room
    local to = room:getPlayerById(data.extra_data.os__gonggeTarget)
    if not to:isAlive() then
      room:setPlayerMark(player, "@os__gongge", 0)
    end
    local x = #getTrueSkills(to)
    if player:getMark("@os__gongge") == "os__gonggeDiscard" then
      if to.hp >= player.hp then
        local cids
        if #player:getCardIds("he") > x then
          cids = room:askToCards(
            player,
            {
              min_num = x,
              max_num = x,
              include_equip = true,
              skill_name = skillName,
              prompt = "#os__gongge-cards::" .. to.id .. ":" .. x,
            }
          )
        else
          cids = player:getCardIds("he")
        end
        if #cids > 0 then
          room:moveCardTo(cids, Player.Hand, to, fk.ReasonGive, skillName, nil, false, player)
        end
      end
    elseif player:getMark("@os__gongge") == "os__gonggeDamage" then
      room:recover{
        who = to,
        num = math.min(x, to.maxHp - to.hp),
        recoverBy = player,
        skillName = skillName,
      }
    end
    room:setPlayerMark(player, "@os__gongge", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return
      player:getMark("@os__gongge") == "os__gonggeDraw" and
      data.responseToEvent and
      data.responseToEvent.from == player and
      (data.responseToEvent.extra_data or {}).os__gonggeTarget == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__gongge_skip", 1)
  end,
})

osGongge:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.phase == Player.Draw and
      not data.skipped and
      player:getMark("@@os__gongge_skip") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__gongge_skip", 0)
    data.skipped = true
  end,
})

osGongge:addEffect(fk.CardRespondFinished, {
  can_refresh = function(self, event, target, player, data)
    return
      player:getMark("@os__gongge") == "os__gonggeDraw" and
      data.responseToEvent and
      data.responseToEvent.from == player and
      (data.responseToEvent.extra_data or {}).os__gonggeTarget == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__gongge_skip", 1)
  end,
})

return osGongge
