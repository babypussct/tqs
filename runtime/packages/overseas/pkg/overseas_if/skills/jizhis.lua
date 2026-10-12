local jizhis = fk.CreateSkill{
  name = "os__jizhis",
  tags = { Skill.Permanent },
  related_skills = { "os__huju" },
}

Fk:loadTranslationTable{
  ["os__jizhis"] = "寄志",
  [":os__jizhis"] = "持恒技，当你进入濒死状态时，你可以选择任意名角色，你令这些角色失去〖虎踞〗，然后你回复等量体力并获得等量的伤害牌，" ..
  "将其余角色的〖虎踞〗转化为“阳”，然后<a href='os_tuihuan_sunce'>“退幻”</a>。",

  ["os_tuihuan_sunce"] = "变身为表形态：<br>" ..
  "<b>励伍</b>：锁定技，有角色的受伤状态发生变化后，你摸一张牌，若其中有基本牌，你下一次造成伤害+1。<br>" ..
  "<b>扫庭</b>：转换技，阳：你可以将一张伤害牌当【决斗】使用；阴：你可以将一张伤害牌当【杀】使用。" ..
  "若你以此法使用牌指定了已受伤角色为目标，你摸一张牌。<br>" ..
  "<b>翦魇</b>：持恒技，游戏开始时，你令所有角色获得〖虎踞〗。" ..
  "当有角色进入濒死状态时，你可以选择任意名（可以为0）角色，你令这些角色失去〖虎踞〗，然后你回复等量体力并获得等量的非伤害牌，" ..
  "将其余角色的〖虎踞〗转化为“阴”，然后<a href='os_ruhuan_sunce'>“入幻”</a>。",

  ["#os__jizhis-choose"] = "寄志：选择任意名角色失去“虎踞”，你回复等量体力并获得等量的伤害牌",

  ["$os__jizhis1"] = "三江已靖，四海之业当由汝开创！",
  ["$os__jizhis2"] = "今非哭泣之时，汝当继父兄之任。",
}

local U = require "packages.utility.utility"

jizhis:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jizhis.name) and
    table.find(player.room.alive_players, function(t)
      return t:hasSkill("os__huju", true)
    end) and player.hp <= 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:hasSkill("os__huju", true)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      skill_name = jizhis.name,
      cancelable = true,
      prompt = "#os__jizhis-choose",
    })
    if #tos == 0 then return end
    room:sortByAction(tos)
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    local n = #tos
    if n > 0 then
      for _, to in ipairs(tos) do
        if to:isAlive() then
          room:handleAddLoseSkills(to, "-os__huju")
        end
      end
      if player:isAlive() then
        room:recover{
          who = player,
          num = n,
        }
      end
      if player:isAlive() then
        local cards = table.filter(room.draw_pile, function (id)
          return Fk:getCardById(id).damage_type ~= nil
        end)
        if #cards > 0 then
          room:moveCardTo(room:tableRandomPick(cards, n), Card.PlayerHand, player, fk.ReasonJustMove, jizhis.name, nil, false, player)
        end
      end
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and not table.contains(tos, p) and p:hasSkill("os__huju", true) then
        U.SetSwitchSkillState(p, "os__huju")
      end
    end
    if player:isAlive() then
      room:handleAddLoseSkills(player, "-os__suzhen|-os__dangjiang|-os__jizhis|os__liwu|os__saoting|os__jianyanc")
      if player.general == "os_if__sunce" then
        room:setPlayerProperty(player, "general", "os_if_huan__sunce")
      end
      if player.deputyGeneral == "os_if__sunce" then
        room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__sunce")
      end
    end
  end
})

return jizhis
