local jianyanc = fk.CreateSkill {
  name = "os__jianyanc",
  tags = { Skill.Permanent },
  related_skills = { "os__huju" },
}

Fk:loadTranslationTable {
  ["os__jianyanc"] = "翦魇",
  [":os__jianyanc"] = "持恒技，游戏开始时，你令所有角色获得〖虎踞〗。" ..
  "当有角色进入濒死状态时，你可以选择任意名角色（可以为0），你令这些角色失去〖虎踞〗，然后你回复等量体力并获得等量的非伤害牌，" ..
  "将其余角色的〖虎踞〗转化为“阴”，然后<a href='os_ruhuan_sunce'>“入幻”</a>。",

  ["os_ruhuan_sunce"] = "变身为幻形态：<br>" ..
  "<b>肃阵</b>：锁定技，有角色的受伤状态发生变化后，你获得其一张牌（若为你则改为展示一张牌），若其中有基本牌，你回复1点体力。<br>" ..
  "<b>荡疆</b>：转换技，阳：你可以将一张非伤害牌当【无中生有】使用；阴：你可以将一张非伤害牌当【杀】使用。" ..
  "若你以此法使用牌指定了未受伤角色为目标，你摸一张牌。<br>" ..
  "<b>寄志</b>：持恒技，当你进入濒死状态时，你可以选择任意名角色，你令这些角色失去〖虎踞〗，然后你回复等量体力并获得等量的伤害牌，" ..
  "将其余角色的〖虎踞〗转化为“阳”，然后<a href='os_tuihuan_sunce'>“退幻”</a>。",

  ["#os__jianyanc-choose"] = "翦魇：选择任意名（可为0）角色失去〖虎踞〗，然后你入幻",

  ["$os__jianyanc1"] = "今九州俱裂，然终为我囊中之物！", -- 开局
  ["$os__jianyanc2"] = "踞三江以观成败，再伺进图之机。", -- 自己濒死
  ["$os__jianyanc3"] = "攻伐无往不利，霸业当在此时！", -- 其他角色濒死
}

local U = require "packages.utility.utility"

jianyanc:addEffect(fk.GameStart, {
  audio_index = 1,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jianyanc.name)
  end,
  on_cost = function (self, event, target, player, data)
    local others = player.room:getAlivePlayers(false)
    event:setCostData(self, {tos = others})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    local room = player.room
    table.forEach(tos, function (to)
      if to:isAlive() then
        room:handleAddLoseSkills(to, "os__huju")
      end
    end)
  end
})

jianyanc:addAuxActiveSkill("#os__huju_active", {
  card_num = 0,
  min_target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return to_select:hasSkill("os__huju", true)
  end,
})

jianyanc:addEffect(fk.EnterDying, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jianyanc.name) and target.hp <= 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#os__huju_active",
      prompt = "#os__jianyanc-choose",
    })
    if success and dat then
      room:sortByAction(dat.targets)
      event:setCostData(self, { tos = dat.targets, audio_index = target == player and 2 or 3 })
      return true
    end
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
          return Fk:getCardById(id).damage_type == nil
        end)
        if #cards > 0 then
          room:moveCardTo(room:tableRandomPick(cards, n), Card.PlayerHand, player, fk.ReasonJustMove, jianyanc.name, nil, false, player)
        end
      end
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and not table.contains(tos, p) and p:hasSkill("os__huju", true) then
        U.SetSwitchSkillState(p, "os__huju")
      end
    end
    if player:isAlive() then
      room:handleAddLoseSkills(player, "-os__liwu|-os__saoting|-os__jianyanc|os__suzhen|os__dangjiang|os__jizhis")
      if player.general == "os_if__sunce" then
        room:setPlayerProperty(player, "general", "os_if_huan__sunce")
      end
      if player.deputyGeneral == "os_if__sunce" then
        room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__sunce")
      end
    end
  end
})

return jianyanc
