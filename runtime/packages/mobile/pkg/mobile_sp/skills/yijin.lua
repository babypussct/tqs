local yijin = fk.CreateSkill {
  name = "yijin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yijin"] = "亿金",
  [":yijin"] = "锁定技，游戏开始时，你获得6枚“金”标记；回合开始时，若你没有“金”，你死亡。出牌阶段开始时，你令一名没有“金”的其他角色获得一枚“金”和"..
  "对应的效果直到其下回合结束：<br>膴士：摸牌阶段摸牌数+4、出牌阶段使用【杀】次数上限+1；<br>厚任：回合结束时回复3点体力；<br>"..
  "贾凶：出牌阶段开始时失去1点体力，本回合手牌上限-3；<br>拥蔽：跳过摸牌阶段；<br>通神：防止受到的非雷电伤害；<br>金迷：跳过出牌阶段和弃牌阶段。",

  ["@[:]yijin_owner"] = "亿金",
  ["@[:]yijin"] = "",
  ["#yijin-choose"] = "亿金：将一种“金”交给一名其他角色",
  ["@$yijin"] = "金",
  ["yijin_wushi"] = "膴士",
  [":yijin_wushi"] = "摸牌阶段摸牌数+4、出牌阶段使用【杀】次数+1",
  ["yijin_houren"] = "厚任",
  [":yijin_houren"] = "回合结束时回复3点体力",
  ["yijin_guxiong"] = "贾凶",
  [":yijin_guxiong"] = "出牌阶段开始时失去1点体力，手牌上限-3",
  ["yijin_yongbi"] = "拥蔽",
  [":yijin_yongbi"] = "跳过摸牌阶段",
  ["yijin_tongshen"] = "通神",
  [":yijin_tongshen"] = "防止受到的非雷电伤害",
  ["yijin_jinmi"] = "金迷",
  [":yijin_jinmi"] = "跳过出牌阶段和弃牌阶段",

  ["$yijin1"] = "吾家资巨万，无惜此两贯三钱！",
  ["$yijin2"] = "小儿持金过闹市，哼！杀人何需我多劳！",
  ["$yijin3"] = "普天之下，竟有吾难市之职？",
}

yijin:addAuxActiveSkill("#yijin_active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    return UI.ComboBox { choices = player:getTableMark("@[:]yijin_owner") }
  end,
  prompt = function (self)
    return self.interaction.data and Fk:translate(":" .. self.interaction.data) or ""
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player and to_select:getMark("@[:]yijin") == 0
  end,
})

yijin:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yijin.name)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "special")

    local golds = {
      "yijin_wushi",
      "yijin_houren",
      "yijin_guxiong",
      "yijin_yongbi",
      "yijin_tongshen",
      "yijin_jinmi",
    }
    room:setPlayerMark(player, "@[:]yijin_owner", golds)
  end,
})

yijin:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yijin.name) and
      #player:getTableMark("@[:]yijin_owner") == 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 3)
    room:notifySkillInvoked(player, skillName, "negative")
    room:killPlayer{ who = player }
  end,
})

yijin:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(yijin.name) and #player:getTableMark("@[:]yijin_owner") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return p:getMark("@[:]yijin") == 0 end)

    if #targets == 0 then
      return false
    end
    local _, dat = room:askToUseActiveSkill(player, { skill_name = "#yijin_active", prompt = "#yijin-choose", cancelable = false })
    local to = (dat and #dat.targets > 0) and dat.targets[1] or room:tableRandomPick(targets)
    local mark = player:getMark("@[:]yijin_owner")
    local choice = dat and dat.interaction or room:tableRandomPick(mark)
    table.removeOne(mark, choice)
    room:setPlayerMark(player, "@[:]yijin_owner", mark)
    room:setPlayerMark(to, "@[:]yijin", choice)
    if table.contains({ "yijin_wushi", "yijin_houren", "yijin_tongshen" }, choice) then
      player:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(player, skillName, "support")
    else
      player:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(player, skillName, "control")
    end
  end,
})

yijin:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    return target == player and mark ~= 0 and mark == "yijin_wushi"
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill(skillName, true) end)
    if src then
      src:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(src, skillName, "support")
    end
    data.n = data.n + 4
  end,
})

yijin:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    return
      target == player and
      (
        (data.phase == Player.Draw and mark == "yijin_yongbi") or
        ((data.phase == Player.Play or data.phase == Player.Discard) and mark == "yijin_jinmi")
      )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill(skillName, true) end)
    if src then
      src:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(src, skillName, "control")
    end
    data.skipped = true
  end,
})

yijin:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    return target == player and player:isWounded() and mark == "yijin_houren"
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill(skillName, true) end)
    if src then
      src:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(src, skillName, "support")
    end
    room:recover{
      who = player,
      num = math.min(3, player:getLostHp()),
      recoverBy = player,
      skillName = skillName,
    }
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@[:]yijin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[:]yijin", 0)
  end,
})

yijin:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    return target == player and player.phase == Player.Play and mark == "yijin_guxiong"
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill(skillName, true) end)
    if src then
      src:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(src, skillName, "control")
    end
    room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 3)
    room:loseHp(player, 1, skillName)
  end,
})

yijin:addEffect(fk.DetermineDamageInflicted, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    return target == player and data.damageType ~= fk.ThunderDamage and mark == "yijin_tongshen"
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yijin.name
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill(skillName, true) end)
    if src then
      src:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(src, skillName, "support")
    end
    data:preventDamage()
  end,
})

yijin:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@[:]yijin") == "yijin_wushi" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return yijin
