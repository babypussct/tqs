local desc_1v1 = [[
  # 1v1模式简介

  两人进行对战的竞技化模式，进行车轮战，先死亡第三张武将的玩家失败，对手获胜。

  ___

  ## 游戏流程

  1. **决定行动顺序**。随机决定先手角色和后手角色。

  2. **挑选武将**。抽取12张武将牌，正面朝上亮出，由后手玩家开始，按照1222221的顺序选择武将。（以下暂无）从所有武将中先每人随机分配3张武将牌作为暗将，暗将对对方保密。然后从剩余武将牌中随机抽取6张，正面朝上亮出，由后手玩家开始，按照1221的顺序选择武将。

  3. **选择第一名登场武将**。双方各从自己所拥有的6张武将牌中选择首发武将，同时正面朝上亮出。

  4. **分发起始手牌**。双方各自摸X张牌，作为其起始手牌（X为体力上限且至多为5）。

  5. **游戏开始**。由先手玩家先开始自己的回合，且首回合摸牌阶段摸牌数-1。后手玩家回合结束后，先手玩家回合开始，依次轮流直到游戏结束。

  6. **武将死亡**。当某一角色的武将死亡时，若游戏未结束，则弃置其区域内的所有牌，由该玩家选择下一名登场武将，然后并摸起始手牌。特别地，如果玩家在自己的回合内武将死亡，则其回合立即结束。

  7. **游戏结束**。当某一角色的第三名登场武将死亡时，游戏立即结束，对手获胜。

]]

-- 从武将池中移除指定武将。若无法移除，则移去第一个武将
local function removeGeneral(generals, g)
  local gt = Fk.generals[g].trueName
  for i, v in ipairs(generals) do
    if Fk.generals[v].trueName == gt then
      return table.remove(generals, i)
    end
  end
  return table.remove(generals, 1)
end

local m_1v1_getLogic = function()
  local m_1v1_logic = GameLogic:subclass("m_1v1_logic")

  function m_1v1_logic:chooseGenerals()
    local room = self.room ---@type Room

    local lord = room.players[1]
    room:setCurrent(lord)
    local nonlord = room.players[2]

    room:setPlayerProperty(nonlord, "role_shown", true)
    room:broadcastProperty(nonlord, "role")

    local lord_generals = {}
    local nonlord_generals = {}
    local all_generals = room:getNGenerals(12)
    local first_selected, second_selected = {}, {}
    -- 用于储存双方已选择武将的序号（从0开始），不用字符串储存是考虑替换武将的情况

    local updataGeneralPile = function(p)
      if p == lord then
        room:setBanner("@&firstGenerals", lord_generals)
      else
        room:setBanner("@&secondGenerals", nonlord_generals)
      end
    end

    local function chooseGeneral(p, n)
      local prompt = "#1v1_mode-choose:::"..(p == lord and "firstPlayer" or "secondPlayer")..":"..n
      local my_selected = (p == lord) and first_selected or second_selected
      local ur_selected = (p == lord) and second_selected or first_selected
      local my_genrals = (p == lord) and lord_generals or nonlord_generals
      local result = room:askToCustomDialog(p, {
        skill_name = "m_1v1_mode",
        component = {
          url = "packages/gamemode/qml/1v1.qml",
          prop = {
            -- 按照QML文件中对属性的定义填写prop
            generals = all_generals,
            num = n,
            my_selected = my_selected,
            ur_selected = ur_selected,
            prompt = prompt,
          }
        },
      })
      local selected = {}
      if result ~= "" then
        ---@cast result any
        for i, id in ipairs(result.ids) do
          local g = result.generals[i]
          -- 更新武将替换
          all_generals[id+1] = g
          table.insert(my_selected, id)
          table.insert(my_genrals, g)
          table.insert(selected, g)
        end
      else
        local selected_list = table.connect(my_selected, ur_selected)
        for i, g in ipairs(all_generals) do
          if not table.contains(selected_list, i-1) then
            table.insert(my_selected, i-1)
            table.insert(my_genrals, g)
            table.insert(selected, g)
            if #selected == n then break end
          end
        end
      end
      room:sendLog{
        type = "#1v1ChooseGeneralsLog",
        arg = p == lord and "firstPlayer" or "secondPlayer",
        arg2 = selected[1],
        arg3 = selected[2] or "",
        toast = true,
      }
      updataGeneralPile(p)
    end

    -- 1-2-2-2-2-2-1
    chooseGeneral(nonlord, 1)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 2)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 2)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 1)

    room:doBroadcastNotify("ShowToast", Fk:translate("1v1 choose general"))
    local req = Request:new(room.players, "AskForGeneral")
    req.timeout = self.room:getSettings('generalTimeout')
    req:setData(lord, { lord_generals, 1 })
    req:setData(nonlord, { nonlord_generals, 1 })
    req:setDefaultReply(lord, { lord_generals[1] })
    req:setDefaultReply(nonlord, { nonlord_generals[1] })
    req:ask()

    for _, p in ipairs(room.players) do
      local tab = p == lord and lord_generals or nonlord_generals
      local chosen = req:getResult(p)[1]
      room:setPlayerGeneral(p, chosen, true, true)
      removeGeneral(tab, chosen)
    end

    room:broadcastProperty(lord, "role")
    room:broadcastProperty(nonlord, "role")
    room:broadcastProperty(lord, "general")
    room:broadcastProperty(nonlord, "general")
    room:broadcastProperty(lord, "kingdom")
    room:broadcastProperty(nonlord, "kingdom")
    room:setBanner("@firstFallen", "0 / 3")
    room:setBanner("@secondFallen", "0 / 3")
    updataGeneralPile(lord)
    updataGeneralPile(nonlord)
    room:askToChooseKingdom(room.players)
  end

  return m_1v1_logic
end

local m_1v1_mode = fk.CreateGameMode{
  name = "m_1v1_mode",
  minPlayer = 2,
  maxPlayer = 2,
  rule = "#m_1v1_rule&",
  logic = m_1v1_getLogic,
  surrender_func = function(self, playedTime)
    return { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
  end,
  build_draw_pile = function(self)
    local draw_pile, void = GameMode.buildDrawPile(self)
    local room = Fk:currentRoom()

    for i = #draw_pile, 1, -1 do
      local id = draw_pile[i]
      local card = Fk:getCardById(id)
      if card.name == "dismantlement" then
        table.insert(void, id)
        -- 因为是双端都要进行一次印卡，所以不要用Room的方法
        local newCard = AbstractRoom.printCard(room, "v11__dismantlement", card.suit, card.number)
        draw_pile[i] = newCard.id
      end
    end

    return draw_pile, void
  end
}
Fk:loadTranslationTable{
  ["m_1v1_mode"] = "1v1",
  ["#1v1ChooseGeneralsLog"] = "%arg 选择了 %arg2 %arg3",
  ["firstPlayer"] = "先手",
  ["secondPlayer"] = "后手",
  ["#1v1_mode-choose"] = "你是[%arg]，请选择 %arg2 张武将牌作为备选",
  ["1v1 choose general"] = "请选择第一名出战的武将",
  ["#1v1Score"] = "已阵亡武将数 先手 %arg : %arg2 后手",
  ["@firstFallen"] = "先手阵亡数",
  ["@secondFallen"] = "后手阵亡数",
  ["@&firstGenerals"] = "先手备选区",
  ["@&secondGenerals"] = "后手备选区",
  ["@&firstExiled"] = "先手流放区",
  ["@&secondExiled"] = "后手流放区",

  [":m_1v1_mode"] = desc_1v1,
}

return m_1v1_mode
