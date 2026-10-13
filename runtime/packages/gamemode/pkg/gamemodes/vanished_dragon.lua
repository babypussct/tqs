local desc_vanished_dragon = [[
  # 忠胆英杰（明忠模式）简介

  ---

  ## 身份说明

  游戏由八名玩家进行，身份分配和一般身份局一样，为1主2忠4反1内。

  其中一名忠臣改为「**明忠**」。抽取身份后，**主公不需要亮明身份，改为明忠亮明身份**。

  胜负判定：和一般身份局一致。

  ---

  ## 游戏流程

  1. **明忠如一般身份局的主公一样，先选将并展示**，其他人（包括主公）再选将。明忠的固定额外选将为 崔琰 和 皇甫嵩(若在房间禁表则不会出现)；

  2. 明忠根据体力上限(不计明忠血量上限加成)和性别获得相应的“**忠臣技**”，即：

  - 体力上限不大于3的男性武将获得〖**洞察**〗（游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌）；

  - 体力上限不小于4的男性武将和所有女性武将获得〖**舍身**〗（锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡）；

  3. 如一般身份局的主公一样，**明忠体力上限和体力值+1**，且为一号位；

  4. **明忠死亡后，主公亮明身份**，获得武将牌上的主公技，但不增加体力上限。

  ---

  ## 击杀奖惩

  1. 任何角色击杀反贼，摸三张牌；

  2. 除主公外的角色击杀明忠，摸三张牌；

  3. 暗主击杀明忠，弃置所有牌；

  4. 暗主击杀暗忠，不弃牌；

  5. 明忠击杀暗忠，弃置所有牌。

  ---

  ## 专属游戏牌

  【**声东击西**】（替换【顺手牵羊】）普通锦囊：出牌阶段，对距离为1的一名角色使用。你交给目标角色一张手牌，然后其将两张牌交给一名由你选择的除其以外的角色。

  【**草木皆兵**】（替换【兵粮寸断】），延时锦囊：出牌阶段，对一名其他角色使用。将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。

  【**增兵减灶**】（替换【无中生有】和【五谷丰登】），普通锦囊：出牌阶段，对一名角色使用。目标角色摸三张牌，然后选择一项：1. 弃置一张非基本牌；2. 弃置两张牌。

  【**弃甲曳兵**】（替换【借刀杀人】），普通锦囊：出牌阶段，对一名装备区里有牌的其他角色使用。目标角色选择一项：1. 弃置手牌区和装备区里所有的武器和进攻坐骑；2. 弃置手牌区和装备区里所有的防具和防御坐骑。

  【**金蝉脱壳**】（替换【无懈可击】），普通锦囊：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】，使目标锦囊牌或基本牌对你无效，你摸两张牌。当你因弃置而失去【金蝉脱壳】时，你摸一张牌。

  【**浮雷**】（替换【闪电】），延时锦囊：出牌阶段，对你使用。将【浮雷】放置于你的判定区里，若判定结果为♠，则目标角色受到X点雷电伤害（X为此牌判定结果为♠的次数）。判定完成后，将此牌移动到下家的判定区里。

  【**烂银甲**】（替换【八卦阵】），防具：你可以将一张手牌当【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。

  【**七宝刀**】（替换【青釭剑】），武器，攻击范围２：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。

  【**衠钢槊**】（替换【青龙偃月刀】），武器，攻击范围３：当你使用【杀】指定一名角色为目标后，你可令其弃置你的一张手牌，然后你弃置其一张手牌。
]]


local vanished_dragon_getLogic = function()
  local vanished_dragon_logic = GameLogic:subclass("vanished_dragon_logic")

  function vanished_dragon_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, nil, nil, nil,
    {"lord", "loyalist", "rebel", "rebel", "rebel", "renegade"},
    {"lord", "loyalist", "loyalist", "rebel", "rebel", "rebel", "renegade"},
    {"lord", "loyalist", "loyalist", "rebel", "rebel", "rebel", "rebel", "renegade"} }
  end

  function vanished_dragon_logic:assignRoles()
    local room = self.room---@type Room
    local players = room.players
    local n = #players
    local roles = self.role_table[n]
    table.shuffle(roles)

    room:setBanner("ShownLoyalist", nil)
    for i = 1, n do
      local p = players[i]
      p.role = roles[i]
      room:broadcastProperty(p, "role")
      if p.role == "loyalist" and not room:getBanner("ShownLoyalist") then
        room:setPlayerProperty(p, "role_shown", true)
        room:setBanner("ShownLoyalist", p.id)
      end
    end
  end

  function vanished_dragon_logic:adjustSeats()
    local player_circle = {}
    local players = self.room.players
    local p = 1

    for i = 1, #players do
      if players[i].id == self.room:getBanner("ShownLoyalist") then
        p = i
        break
      end
    end
    for j = p, #players do
      table.insert(player_circle, players[j])
    end
    for j = 1, p - 1 do
      table.insert(player_circle, players[j])
    end

    self.room:arrangeSeats(player_circle)
  end

  function vanished_dragon_logic:chooseGenerals()
    local room = self.room---@type Room

    local generals_blacklist = {
      -- 明忠备选
      "vd__cuiyan", "vd__huangfusong",
      -- 暴露暗主
      "js__caocao", "js__zhugeliang", "ol__dongzhao", "std__yuanshu", "huanghao", "mou__guanyu", "godlusu",
      "mobile__yuanshu", "m_ex__yuanshu", "guandu__xuyou",
      -- 傻逼武将
      "ofl__yingzheng", "wuzhao",
    }
    local loyalist_list = {}
    for i = #room.general_pile, 1, -1 do
      local name = room.general_pile[i]
      if table.contains(generals_blacklist, name) then
        if name == "cuiyan" or name == "vd__huangfusong" then
          table.insert(loyalist_list, name)
        end
        table.remove(room.general_pile, i)
      end
    end

    local generalNum = room:getSettings('generalNum')
    local lord = room.players[1] -- room:getLord()
    if lord.id == room:getBanner("ShownLoyalist") then
      for _, p in ipairs(room.players) do
        if p.id == room:getBanner("ShownLoyalist") then
          lord = p
          break
        end
      end
    end

    room:sendLog{
      type = "#VDIntro",
      arg = lord._splayer:getScreenName(),
      toast = true,
    }

    room:setCurrent(lord)
    table.insertTable(loyalist_list, room:getNGenerals(generalNum))
    local lord_res = room:askToChooseIniticalGeneral(lord, {
      targets = lord,
      generals = loyalist_list,
      needDeputy = room:getSettings('enableDeputy'),
    })

    room:broadcastProperty(lord, "kingdom")

    -- 显示技能
    local canAttachSkill = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return false
      end
      if skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
        return false
      end
      return true
    end

    local lord_skills = {}
    local lord_gs = Fk.generals[lord_res[lord][1]]
    for _, s in ipairs(lord_gs:getSkillNameList()) do
      if canAttachSkill(lord, s) then
        table.insertIfNeed(lord_skills, s)
      end
    end
    local deputyGeneral = Fk.generals[lord_res[lord][2]]
    if deputyGeneral then
      for _, s in ipairs(deputyGeneral:getSkillNameList()) do
        if canAttachSkill(lord, s) then
          table.insertIfNeed(lord_skills, s)
        end
      end
    end
    local lord_maxhp = deputyGeneral and (lord_gs.maxHp + deputyGeneral.maxHp) // 2 or lord_gs.maxHp
    table.insert(lord_skills, (lord_maxhp <= 3 and lord_gs:isMale()) and "vd_dongcha" or "vd_sheshen")
    for _, skill in ipairs(lord_skills) do
      room:doBroadcastNotify("AddSkill", { lord.id, skill })
    end

    local nonlord = room:getOtherPlayers(lord, true)
    room:askToChooseIniticalGeneral(lord, {
      targets = nonlord,
      num = generalNum,
      needDeputy = room:getSettings('enableDeputy'),
      lordGeneral = lord.general,
      lordDeputy = lord.deputyGeneral,
      lordRole = "loyalist",
    })
  end


  function vanished_dragon_logic:attachSkillToPlayers()
    local room = self.room
    local players = room.players
    local lord = room:getBanner("ShownLoyalist")

    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if skill:hasTag(Skill.Lord) then
        return
      end

      if skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
        return
      end

      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      local skills = Fk.generals[p.general].skills
      for _, s in ipairs(skills) do
        addRoleModSkills(p, s.name)
      end
      for _, sname in ipairs(Fk.generals[p.general].other_skills) do
        addRoleModSkills(p, sname)
      end

      local deputy = Fk.generals[p.deputyGeneral]
      if deputy then
        skills = deputy.skills
        for _, s in ipairs(skills) do
          addRoleModSkills(p, s.name)
        end
        for _, sname in ipairs(deputy.other_skills) do
          addRoleModSkills(p, sname)
        end
      end

      if p.id == lord then
        local skill = (p.maxHp <= 4 and p:isMale()) and "vd_dongcha" or "vd_sheshen"
        room:sendLog{
          type = "#VDLoyalistSkill",
          from = p.id,
          arg = skill,
          toast = true,
        }
        room:handleAddLoseSkills(p, skill, nil, false)
      end
    end
  end

  return vanished_dragon_logic
end

local vanished_dragon = fk.CreateGameMode{
  name = "vanished_dragon",
  minPlayer = 6,
  maxPlayer = 8,
  main_mode = "role_mode",
  rule = "#vanished_dragon_rule&",
  logic = vanished_dragon_getLogic,
  surrender_func = function(self, playedTime, player)
    return Fk.game_modes["aaa_role_mode"]:surrenderFunc(playedTime, player)
  end,
  get_adjusted = function (self, player)
    if player.room:getBanner("ShownLoyalist") == player.id then
      return {hp = player.hp + 1, maxHp = player.maxHp + 1}
    end
    return {}
  end,
  winner_getter = function (self, victim)
    return Fk.game_modes["aaa_role_mode"]:getWinner(victim)
  end,
  reward_punish = function (self, victim, killer)
    if not killer or killer.dead then return end
    local shownLoyalist = victim.room:getBanner("ShownLoyalist")
    if victim.role == "loyalist" and ((killer.role == "lord" and killer.role_shown) or killer.id == shownLoyalist) then
      killer:throwAllCards("he")
    elseif victim.role == "rebel" or victim.id == shownLoyalist or killer.role == "wild" then
      killer:drawCards(3, "kill")
    end
  end,
  build_draw_pile = function(self)
    local draw, void = GameMode.buildDrawPile(self)
    local blacklist = {
      "snatch", "supply_shortage", "ex_nihilo", "amazing_grace", "collateral", "nullification",
      "lightning", "eight_diagram", "qinggang_sword", "blade"
    }
    local whitelist = {
      "diversion", "paranoid", "reinforcement", "abandoning_armor", "crafty_escape",
      "floating_thunder", "glittery_armor", "seven_stars_sword", "steel_lance"
    }

    for i = #void, 1, -1 do
      local id = void[i]
      local card = Fk:getCardById(id)
      local name = card.name
      if table.contains(whitelist, name) then
        table.remove(void, i)
        table.insert(draw, id)
      end
    end

    for i = #draw, 1, -1 do
      local id = draw[i]
      local card = Fk:getCardById(id)
      local name = card.name
      if table.contains(blacklist, name) then
        table.remove(draw, i)
        table.insert(void, id)
      end
    end

    return draw, void
  end
}

Fk:loadTranslationTable{
  ["vanished_dragon"] = "忠胆英杰",
  [":vanished_dragon"] = desc_vanished_dragon,
  ["#VDIntro"] = "<b>%arg</b> 是 <b>明忠</b>，<b>开始选将</b><br>明忠是代替主公亮出身份牌的忠臣，明忠死后主公再翻出身份牌",
  ["#VDLoyalistSkill"] = "明忠 %from 获得忠臣技：%arg",
}

return vanished_dragon
