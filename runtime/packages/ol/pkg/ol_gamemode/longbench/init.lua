local desc = dofile 'packages/ol/pkg/ol_gamemode/longbench/readme.md'
--[[
|          |    魏    |    蜀    |    吴    |    群    |
|----------|----------|----------|----------|----------|
|    标    |          |  黄月英  |   孙权   |          |
|    界    |   曹操   |   张飞   |   甘宁   |   吕布   |
|          |  司马懿  |   赵云   |   周瑜   |  公孙瓒  |
|          |  夏侯惇  |   徐庶   |          |          |
|          |   张辽   |          |          |          |
|          |   许褚   |          |          |          |
|          |   郭嘉   |          |          |          |
|          |   李典   |          |          |          |
|   神话   |   典韦   |   庞统   |   孙坚   |   庞德   |
|          |   邓艾   |   卧龙   |   孙策   | 颜良文丑 |
|          |          |   祝融   |          |   贾诩   |
|          |          |   孟获   |          |          |
|          |          |   姜维   |          |          |
|   一将   |   于禁   |   马谡   |   徐盛   |   李儒   |
|          |   曹植   | 关兴张苞 |   韩当   |          |
|          |   曹彰   |   关平   |   虞翻   |          |
|          |   荀攸   |   刘封   |   朱然   |          |
|          |   曹冲   |   刘谌   |   朱桓   |          |
|          |   郭淮   |   张嶷   |   顾雍   |          |
|          | 韩浩史涣 |          |   孙休   |          |
|          |   曹休   |          |          |          |
|   原创   |  郭皇后  |          |   孙登   |          |
|    SP    |   庞德   |  关银屏  |  诸葛瑾  |   伏完   |
|          |   曹仁   |  夏侯霸  |          |   潘风   |
|          |  司马朗  |          |          |          |
|          |   李通   |          |          |          |
|          |   乐进   |          |          |          |
|          |   姜维   |          |          |          |
|   阴雷   |          |          |          |   袁术   |
]]
local general_pool = {
  -- 标：黄月英、孙权
  "huangyueying", "sunquan",
  -- OL界包
  "ex__caocao", "ex__zhangfei", "ex__ganning", "ex__lvbu",
  "ex__simayi", "ol_ex__zhaoyun", "ex__zhouyu", "std__gongsunzan",
  "ex__xiahoudun", "std__xushu", "ex__zhangliao", "ex__xuchu",
  "ex__guojia", "lidian",
  -- 神话再临 （庸肆袁术）
  "mobile_ex__pangde", -- "pangde",
  "ol__menghuo",
  "dianwei", "pangtong", "sunjian",
  "dengai", "wolong", "sunce", "yanliangwenchou",
  "zhurong", "jiaxu", "jiangwei", "yuanshu",
  -- 一将成名
  "ol__yujin",
  "re__masu", "re__xusheng", "liru",
  "caozhi", "guanxingzhangbao", "handang", "caozhang",
  "guanping", "yufan", "xunyou", "liufeng", "zhuran",
  "caochong", "liuchen", "zhuhuan", "guohuai", "zhangyi",
  "ol__guyong", "hanhaoshihuan", "sunxiu", "caoxiu",
  -- 原创之魂
  "guohuanghou", "sundeng",
  -- SP
  "1v1_ol_sp__jiangwei", ---FIXME: 神秘的1v1测试依赖来源
  "sp__pangde", "ol__guanyinping", "ol__zhugejin", "fuwan", "ol_sp__caoren",
  "xiahouba", "std__panfeng", "simalang", "litong", "yuejin",
}

local bloodbath_longbench_getLogic = function()
  local bloodbath_longbench_logic = GameLogic:subclass("bloodbath_longbench_logic")

  function bloodbath_longbench_logic:chooseGenerals()
    local room = self.room ---@type Room

    local pools = table.filter(general_pool, function(name)
      return Fk.generals[name] ~= nil
    end)

    if #pools < 12 then
      room:sendLog{
        type = "#NoEnoughGeneralDraw",
        arg = #pools,
        arg2 = 12,
        toast = true,
      }
      room:gameOver("")
    end

    local lord = room.players[1]
    room:setCurrent(lord)
    local nonlord = room.players[2]

    room:setPlayerProperty(nonlord, "role_shown", true)
    room:broadcastProperty(nonlord, "role")

    local all_generals = room:tableRandomPick(pools, 12)--room:getNGenerals(12)
    local lord_generals = table.slice(all_generals, 1, 4)
    local nonlord_generals = table.slice(all_generals, 4, 7)
    local first_selected, second_selected = {}, {}
    all_generals = table.slice(all_generals, 7, 13)

    local function chooseGeneral(p, n)
      local prompt = "#longbench-choose:::"..(p == lord and "firstPlayer" or "secondPlayer")..":"..n
      local my_selected = (p == lord) and first_selected or second_selected
      local ur_selected = (p == lord) and second_selected or first_selected
      local my_genrals = (p == lord) and lord_generals or nonlord_generals
      local result = room:askToCustomDialog(p, {
        skill_name = "bloodbath_longbench",
        component = {
          url = "packages/gamemode/qml/1v1.qml",
          prop = {
            generals = all_generals,
            num = n,
            my_selected = my_selected,
            ur_selected = ur_selected,
            prompt = prompt,
            no_convert = true,
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
        type = "#longbenchChooseGeneralsLog",
        arg = p == lord and "firstPlayer" or "secondPlayer",
        arg2 = table.concat(table.map(selected, Util.TranslateMapper), " "),
        toast = true,
      }
    end

    room:doBroadcastNotify("GameLog", {
      type = "#longbenchChooseGeneralsLog",
      arg = "firstPlayer",
      arg2 = table.concat(table.map(lord_generals, Util.TranslateMapper), " "),
      toast = true,
    }, {lord})

    room:doBroadcastNotify("GameLog", {
      type = "#longbenchChooseGeneralsLog",
      arg = "secondPlayer",
      arg2 = table.concat(table.map(nonlord_generals, Util.TranslateMapper), " "),
      toast = true,
    }, {nonlord})
    -- 1-2-2-1
    chooseGeneral(nonlord, 1)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 2)
    chooseGeneral(lord, 1)

    room:doBroadcastNotify("ShowToast", Fk:translate("longbench choose general"))
    local req = Request:new(room.players, "AskForGeneral")
    req.timeout = self.room:getSettings('generalTimeout')
    req:setData(lord, { lord_generals, 2, true, false })
    req:setData(nonlord, { nonlord_generals, 2, true, false })
    req:setDefaultReply(lord, { lord_generals[1], lord_generals[2] })
    req:setDefaultReply(nonlord, { nonlord_generals[1], nonlord_generals[2] })
    req:ask()

    for _, p in ipairs(room.players) do
      local chosen = req:getResult(p)
      room:setPlayerGeneral(p, chosen[1], true, true)
      room:setDeputyGeneral(p, chosen[2])
    end

    room:broadcastProperty(lord, "role")
    room:broadcastProperty(nonlord, "role")
    room:broadcastProperty(lord, "general")
    room:broadcastProperty(nonlord, "general")
    room:broadcastProperty(lord, "deputyGeneral")
    room:broadcastProperty(nonlord, "deputyGeneral")
    room:broadcastProperty(lord, "kingdom")
    room:broadcastProperty(nonlord, "kingdom")
    room:askToChooseKingdom(room.players)
  end

  return bloodbath_longbench_logic
end

local bloodbath_longbench = fk.CreateGameMode{
  name = "bloodbath_longbench",
  minPlayer = 2,
  maxPlayer = 2,
  rule= "#bloodbath_longbench_rule&",
  logic = bloodbath_longbench_getLogic,
  -- 构建牌堆
  build_draw_pile = function(self)
    local allCardIds, void = GameMode.buildDrawPile(self)
    local room = Fk:currentRoom()

    local to_remove = {
      -- 替换为专用版本
      -- Fk:cloneCard("crossbow", Card.Club, 1),
      -- Fk:cloneCard("crossbow", Card.Diamond, 1),
      -- Fk:cloneCard("supply_shortage", Card.Spade, 10),
      -- Fk:cloneCard("supply_shortage", Card.Club, 4),

      -- 纯移除
      Fk:cloneCard("lightning", Card.Spade, 1),
      Fk:cloneCard("lightning", Card.Heart, 12),
      Fk:cloneCard("vine", Card.Club, 2),
      Fk:cloneCard("nullification", Card.Diamond, 12),
    }

    ---@param card Card
    local function matchAll(card)
      assert(card:isInstanceOf(Card))
      for _, target_card in ipairs(to_remove) do
        if card.name == target_card.name and
          card.suit == target_card.suit and
          card.number == target_card.number then
          return target_card
        end
      end
      return nil
    end

    for i = #allCardIds, 1, -1 do
      local id = allCardIds[i]
      local card = Fk:getCardById(id)
      -- 只移除固定数量
      if table.removeOne(to_remove, matchAll(card)) then
        table.insert(void, id)
        table.remove(allCardIds, i)
      -- 抄袭1v1的改牌堆方法
      elseif card.name == "crossbow" then
        table.insert(void, id)
        local newCard = AbstractRoom.printCard(room, "v11_lb__crossbow", card.suit, card.number)
        allCardIds[i] = newCard.id
      elseif card.name == "supply_shortage" then
        table.insert(void, id)
        local newCard = AbstractRoom.printCard(room, "v11_lb__supply_shortage", card.suit, card.number)
        allCardIds[i] = newCard.id
      end
    end
    return allCardIds, void
  end,
  surrender_func = function (self, playedTime)
    return { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
  end,
}

Fk:loadTranslationTable{
  ["bloodbath_longbench"] = "血战长坂坡",
  [":bloodbath_longbench"] = desc,

  ["firstPlayer"] = "先手",
  ["secondPlayer"] = "后手",
  ["#longbench-choose"] = "你是[%arg]，请选择 %arg2 张武将牌作为备选",
  ["#longbenchChooseGeneralsLog"] = "%arg 选择了 %arg2",
  ["longbench choose general"] = "选择您的武将",

  ["time limitation: 2 min"] = "游戏时长达到2分钟",
}

return bloodbath_longbench
