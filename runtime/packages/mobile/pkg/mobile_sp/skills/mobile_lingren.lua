local mobileLingren = fk.CreateSkill {
  name = "mobile__lingren",
  related_skills = { "jianxiong", "xingshang" },
}

Fk:loadTranslationTable{
  ["mobile__lingren"] = "凌人",
  [":mobile__lingren"] = "每阶段限一次，当你于出牌阶段内使用【杀】或伤害类锦囊牌指定第一个目标后，"..
  "你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得〖奸雄〗和〖行殇〗直到你的下个回合开始。",

  ["#mobile__lingren-choose"] = "是否发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#mobile__lingren-invoke"] = "是否对%dest发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#mobile__lingren-choice"] = "凌人：猜测%dest的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["#mobile__lingren_result"] = "%from 猜对了 %arg 项",

  ["$mobile__lingren1"] = "老将军虎威犹在，可惜命不久矣。",
  ["$mobile__lingren2"] = "此山已为我军所围，尔等若降，还可善终！",
}

mobileLingren:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      data.firstTarget and
      data.card.is_damage_card and
      player:hasSkill(mobileLingren.name) and
      player:usedSkillTimes(mobileLingren.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileLingren.name
    local room = player.room
    local targets = table.filter(data.use.tos, function (p) return p:isAlive() end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#mobile__lingren-invoke::" .. targets[1].id }) then
        room:doIndicate(player, targets)
        event:setCostData(self, targets)
        return true
      end
    else
      targets = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#mobile__lingren-choose",
          skill_name = skillName,
        }
      )
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileLingren.name
    local room = player.room
    local to = event:getCostData(self)[1]
    local choices = { "lingren_basic", "lingren_trick", "lingren_equip" }
    local yes = room:askToChoices(
      player,
      {
        choices = choices,
        min_num = 0,
        max_num = 3,
        skill_name = skillName,
        prompt = "#mobile__lingren-choice::" .. to.id,
        cancelable = false,
      }
    )
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to:getCardIds("h")) do
      local str = "lingren_" .. Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#mobile__lingren_result",
      from = player.id,
      arg = tostring(right),
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.mobile__lingren = data.extra_data.mobile__lingren or {}
      table.insert(data.extra_data.mobile__lingren, to.id)
    end
    if right > 1 then
      player:drawCards(2, skillName)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("jianxiong", true) then
        table.insert(skills, "jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      if #skills > 0 then
        room:setPlayerMark(player, skillName, skills)
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
    end
  end,
})

mobileLingren:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:isAlive() or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data
    return use.extra_data and use.extra_data.mobile__lingren and table.contains(use.extra_data.mobile__lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

mobileLingren:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(mobileLingren.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileLingren.name
    local room = player.room
    local skills = player:getMark(skillName)
    room:setPlayerMark(player, skillName, 0)
    room:handleAddLoseSkills(player, "-" .. table.concat(skills, "|-"), nil, true, false)
  end,
})

return mobileLingren
