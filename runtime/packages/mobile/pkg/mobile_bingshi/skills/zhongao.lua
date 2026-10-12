local zhongao = fk.CreateSkill {
  name = "zhongao",
  tags = { Skill.Quest },
  related_skills = { "m_shi__kuanggu", "kunfen" }
}

Fk:loadTranslationTable{
  ["zhongao"] = "忠傲",
  [":zhongao"] = "使命技，游戏开始时，你获得技能〖狂骨〗。<br>" ..
  "⬤　成功：当你杀死一名角色后，你升级技能〖狂骨〗。若你于此阶段内：使用的牌数小于因〖壮誓〗弃置的牌数，你摸一张牌；" ..
  "使用的牌数小于因〖壮誓〗失去的体力数，你回复1点体力（未受伤则改为摸一张牌）。<br>" ..
  "⬤　失败：当你进入濒死状态时，或你选择不执行技能〖壮誓〗，你失去技能〖壮誓〗并获得技能〖困奋〗。",

  ["$zhongao1"] = "主公有延助力，何忧汉室难兴！",
  ["$zhongao2"] = "此番斩将得胜，只是连捷之始！",
  ["$zhongao3"] = "此身搏杀不懈，只为成主公之业！",
  ["$zhongao4"] = "一时得失何须挂怀，自有再建功业之机！",
  ["$zhongao5"] = "吾身无需担忧，诸位还当奋进。",
}

zhongao:addEffect(fk.GameStart, {
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhongao.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "m_shi__kuanggu")
  end,
})

zhongao:addEffect(fk.Deathed, {
  audio_index = { 2, 3 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhongao.name) and data.killer == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhongao.name
    local room = player.room

    if player.general == "m_shi__weiyan" then
      player.general = "m_shi2__weiyan"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "m_shi__weiyan" then
      player.deputyGeneral = "m_shi2__weiyan"
      room:broadcastProperty(player, "deputyGeneral")
    end

    room:updateQuestSkillState(player, skillName)
    room:invalidateSkill(player, skillName)
    room:setPlayerMark(player, "m_shi__kuanggu_upgrade", 1)
    player:setSkillUseHistory("m_shi__kuanggu", 0, Player.HistoryTurn)

    local zhuangshiBuff = player:getTableMark("@zhuangshi-phase")
    if #zhuangshiBuff > 0 then
      if #zhuangshiBuff > 0 and zhuangshiBuff[1] > 0 then
        player:drawCards(1, skillName)
        if player.dead then return end
      end
      if #zhuangshiBuff > 1 and zhuangshiBuff[2] > 0 then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = skillName,
          }
        else
          player:drawCards(1, skillName)
        end
      end
    end
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.general == "m_shi__weiyan" then
      player.general = "m_shi3__weiyan"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "m_shi__weiyan" then
      player.deputyGeneral = "m_shi3__weiyan"
      room:broadcastProperty(player, "deputyGeneral")
    end

    room:updateQuestSkillState(player, zhongao.name, true)
    room:invalidateSkill(player, zhongao.name)
    room:handleAddLoseSkills(player, "-zhuangshi|kunfen")
  end,
}

zhongao:addEffect(fk.EnterDying, {
  audio_index = { 4, 5 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongao.name) and player.hp < 1
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

zhongao:addEffect(fk.AfterSkillEffect, {
  audio_index = { 4, 5 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongao.name) and
      data.skill.name == "zhuangshi" and (data.skill_data.cost_data or {}).cancelled
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

return zhongao
