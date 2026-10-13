local desc_1v3 = [[
  # 1v3简介

  虎牢关玩法，并基于目前的环境进行了一些魔改，目前处于测试中。

  座位：神吕布-中坚-先锋-大将

  胜利目标为击破全部敌方。

  ## 选择武将

  选将的顺序按照座位依次进行，即先锋-中坚-大将的顺序依次选将。
  
  若启用双将，则盟军选将之前吕布可以选择一名武将作为自己的副将。

  ## 分发初始手牌

  神吕布8张、中坚3张、先锋4张、大将5张。

  ## 阶段与行动顺序

  第一阶段中固定为中坚-吕布-先锋-吕布-大将-吕布，无视座位变化。

  当神吕布的体力值即将降低到4或者更低时或者牌堆首次洗切时，神吕布立刻进入第二阶段：（6血6上限，
  随机变更为暴怒战神或者神鬼无前（若启用双将则改为自选），复原并弃置判定区内所有牌，结束一切结算并
  终止本轮游戏，进入新一轮并由神吕布第一个行动）

  第二阶段后，按照座次正常进行行动。

  ## 其他

  撤退：被神吕布击杀的联军改为休整4轮（若启用双将则改为6轮）。第一阶段中，因休整而消耗的回合不会导致神吕布进行回合。
  
  重整：完成休整后的角色回满并摸6-X张牌（X为其体力值），复活的回合不能行动。

  特殊摸牌：有联军撤退或阵亡时，队友可以选择是否摸两张牌或回复1点体力（若启用双将则改为是否摸一张牌）。

  武器重铸：该模式下武器牌可重铸。

]]

local m_1v3_getLogic = function()
  ---@class Logic1v3: GameLogic
  local m_1v3_logic = GameLogic:subclass("m_1v3_logic")

  function m_1v3_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local roles = { "lord", "rebel", "rebel", "rebel" }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
    end
  end

  function m_1v3_logic:chooseGenerals()
    local room = self.room ---@type Room
    local generalNum = room:getSettings('generalNum')
    local n = room:getSettings('enableDeputy') and 2 or 1
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord() --[[@as ServerPlayer]]
    room:setCurrent(lord)
    for _, p in ipairs(room.players) do
      local general, deputy
      if p.role == "lord" then
        local generals = {}
        for _, g in pairs(Fk.generals) do
          if g.hulao_status == 1 and
            not table.contains(room.disabled_packs, g.package.name) and
            not table.contains(room.disabled_generals, g) then
            table.insert(generals, g)
          end
        end
        generals = table.map(generals, Util.NameMapper)
        general = room:askToChooseGeneral(p, {
          generals = room:tableRandomPick(generals, generalNum),
          n = 1,
        })
        if n == 2 then
          generals = Fk:getGeneralsRandomly(generalNum)
          generals = table.map(generals, Util.NameMapper)
          deputy = room:askToChooseGeneral(p, {
            generals = room:tableRandomPick(generals, generalNum),
            n = 1,
          })
        end
      else
        local generals = Fk:getGeneralsRandomly(generalNum)
        generals = table.map(generals, Util.NameMapper)
        local g = room:askToChooseGeneral(p, {
          generals = generals,
          n = n,
        })
        if n == 1 then g = { g } end
        general, deputy = table.unpack(g)
      end
      room:setPlayerGeneral(p, general, true, true)
      if deputy then
        p.deputyGeneral = deputy
      end
      room:broadcastProperty(p, "general")
      room:broadcastProperty(p, "deputyGeneral")
      room:broadcastProperty(p, "kingdom")
    end
    room:askToChooseKingdom(room:getOtherPlayers(lord))
  end

  function m_1v3_logic:attachSkillToPlayers()
    local room = self.room

    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then return end
      if skill:hasTag(Skill.Lord) then return end

      if skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
        return
      end

      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList(false)) do
        addRoleModSkills(p, s)
      end
      if p.deputyGeneral ~= "" then
        for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(false)) do
          addRoleModSkills(p, s)
        end
      end
      room:handleAddLoseSkills(p, "1v3_recast_weapon&", nil, false)
    end
  end

  ---@class HulaoRound: GameEvent.Round
  local hulaoRound = GameEvent.Round:subclass("HulaoRound")
  function hulaoRound:action()
    local room = self.room

    -- 行动顺序：反1->主->反2->主->反3->主，若已暴怒则正常逻辑
    if not room:getTag("m_1v3_phase2") then
      local lord = room:getLord()
      room:setCurrent(lord) -- getOtherPlayers
      for _, p in ipairs(room:getOtherPlayers(lord, true, true)) do
        local rest = p.dead
        room:setCurrent(p)
        GameEvent.Turn:create(TurnData:new(p)):exec()
        if room.game_finished then break end
        room:actExtraTurn()
        if not rest then
          room:setCurrent(lord)
          GameEvent.Turn:create(TurnData:new(lord)):exec()
          if room.game_finished then break end
          room:actExtraTurn()
        end
      end
    else
      GameEvent.Round.action(self)
    end
  end

  function m_1v3_logic:action()
    self:trigger(fk.GamePrepared)
    local room = self.room

    GameEvent.DrawInitial:create():exec()

    while true do
      hulaoRound:create():exec()
      if room.game_finished then break end
      if table.every(room.players, function(p)
        return p.dead and p.rest == 0
      end) then
        room:gameOver("")
      end
      room:setCurrent(room.players[1])
    end
  end

  return m_1v3_logic
end

local m_1v3_mode = fk.CreateGameMode{
  name = "m_1v3_mode",
  minPlayer = 4,
  maxPlayer = 4,
  rule = "#m_1v3_rule&",
  logic = m_1v3_getLogic,
  surrender_func = function(self, playedTime, player)
    local surrenderJudge = { { text = "time limitation: 5 min", passed = playedTime >= 300 },
    { text = "2v2: left you alive", passed = not table.find(Fk:currentRoom().players, function(p)
      return p ~= player and p.role == player.role and not (p.dead and p.rest == 0)
    end) } }
    return surrenderJudge
  end,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    local n = room:getSettings('enableDeputy') and 2 or 1
    for _, p in ipairs(room.alive_players) do
      if p.role == victim.role and not p.dead then
        if n == 2 then
          if room:askToSkillInvoke(p, {
          skill_name = "PickLegacy",
          prompt = "#m_1v3_death_draw",
        }) then
            p:drawCards(1, "game_rule")
          end
        else
          local choices = {"draw2", "Cancel"}
          if p:isWounded() then
            table.insert(choices, 2, "recover")
          end
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = "PickLegacy",
          })
          if choice == "draw2" then
            p:drawCards(2, "game_rule")
          else
            room:recover{
              who = p,
              num = 1,
              skillName = "game_rule",
            }
          end
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["m_1v3_mode"] = "虎牢关1v3",
  [":m_1v3_mode"] = desc_1v3,
  ["#m_1v3_death_draw"] = "是否摸一张牌？",
  ["#m_1v3_rule"] = "虎牢关规则",
  ["m_1v3_convert"] = "暴怒",
}

return m_1v3_mode
