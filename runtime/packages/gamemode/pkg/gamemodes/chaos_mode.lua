local desc_chaos = [[
  # 文和乱武简介

  ---

  ## 中心规则

  游戏由4~10名玩家进行，**一人一伙，各自为战**，胜利目标为活到最后吃鸡！

  以下主要按照线下版本（文和乱武·战备）规则说明，线上版本有差异的置于括号中，标为灰色。

  游戏目标：按照角色阵亡顺序进行排名，最终存活的玩家获得胜利。

  击杀奖惩：击杀一名角色后，击杀者摸两张牌或回复1点体力<font color="grey">（线上：击杀者加1点体力上限并摸三张牌）</font>。

  不能对其他角色使用【桃】。<font color="grey">（线上：每名角色都有〖完杀〗）</font>

  手气卡无限；游戏开始时，所有角色可以使用任意张装备牌。<font color="grey">（线上：无）</font>

  ---

  ## 特殊事件

  每轮开始时，随机执行一个特殊事件。<font color="grey">首轮固定执行“战备”（线上：第一轮固定为“乱武”）</font>共有以下几条特殊事件：

  **战备**：已受伤角色视为拥有〖八阵〗。（除首轮外不执行）<font color="grey">（线上：无此事件，作为第一轮的额外规则）</font>

  **乱武**：从首位角色<font color="grey">（线上：随机一名角色）</font>开始结算〖乱武〗（所有角色，需对距离最近的一名角色使用一张【杀】，否则失去1点体力）。

  **重赏**：本轮中，击杀角色奖励翻倍。

  **破釜沉舟**：每个回合开始时，当前回合角色失去1点体力，摸三张牌。

  **横刀跃马**：每个回合结束时，所有装备最少的角色失去1点体力，随机将牌堆里的一张装备牌置入其装备区。

  **横扫千军**：本轮中，所有伤害值+1。

  **饿莩载道**：本轮结束时，所有手牌最少的角色失去X点体力。（X为轮数）

  **宴安鸩毒**：本轮中，所有的【桃】均视为【毒】。（【毒】：锁定技，当此牌正面朝上离开你的手牌区后，你失去1点体力。出牌阶段，你可对自己使用。）

  ---

  ## 粮草机制<font color="grey">（线上：无）</font>

  ①每轮开始时，每名角色获得2枚“粮草”标记。

  ②当你对其他角色造成伤害后，你获得其一半的“粮草”（向下取整）。

  ③当你杀死角色后，你获得其全部的“粮草”。

  ④设立特殊公共区域，称为“供给区”，始终展示三张牌；出牌阶段开始时，你可以花费“粮草”购买卡牌，购买一张牌后，用牌堆顶的牌补足供给区的牌至三张。基本牌需2枚“粮草”，非基本牌需3枚“粮草”。

  ---

  ## 特殊锦囊牌

  【**斗转星移**】：出牌阶段，对一名其他角色使用。随机分配你和其的体力（至少为1且无法超出上限）。<font color="#CC3131">♥</font>A/<font color="#CC3131">♦</font>5。

  【**李代桃僵**】：出牌阶段，对一名其他角色使用。随机分配你和其的手牌。<font color="#CC3131">♦</font>Q/<font color="#CC3131">♥</font>A/<font color="#CC3131">♥</font>K。

  【**偷梁换柱**】：出牌阶段，对你使用。随机分配所有角色装备区里的牌。♠J/♣Q/♣K/♠K。

  【**文和乱武**】：出牌阶段，对其他角色使用。目标角色各选择一项：1. 对距离最近的一名角色使用【杀】；2. 失去1点体力。♠10/♣4。

  【**强易**】：出牌阶段，若你有至少2枚手牌，对一名有手牌的其他角色使用。你交给目标角色2枚“粮草”并观看其手牌，获得其手牌区或装备区的一张牌。♠A/♣Q/♣K。<font color="grey">（线上：无）</font>

  【**强兵足食**】：出牌阶段，对你使用。目标角色获得5枚“粮草”。<font color="#CC3131">♥</font>3/<font color="#CC3131">♥</font>4。<font color="grey">（线上：无）</font>

  移除兵、乐、无懈、桃园和木马。

  移除借刀、五谷、黑桃A闪电。<font color="grey">（线上：无）</font>

  ---

  鼓励收人头来“舔包”来加快游戏节奏。

  特殊规则均为了加快游戏进度的效果，并且含有极大随机性，玩家需要提前提防某些情况发生。

  特殊锦囊设置将拖慢游戏节奏的牌移除，改为引进了具有随机性甚至足以改变战局的锦囊牌。
]]

local chaos_getLogic = function()
  local chaos_logic = GameLogic:subclass("chaos_logic")

  function chaos_logic:initialize(room)
    GameLogic.initialize(self, room)
    -- 手气卡无限（线下）
    if (self.room:getSettings("modeChoice") == "chaos_mode_choice:custom") then
      self.room.settings._game.luckTime = 20
    end
  end

  function chaos_logic:assignRoles()
    local room = self.room
    local n = #room.players

    for i = 1, n do
      local p = room.players[i]
      p.role = "hidden"
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function chaos_logic:chooseGenerals()
    local room = self.room
    local generalNum = room:getSettings("generalNum")
    local n = room:getSettings("enableDeputy") and 2 or 1
    local lord = room:getLord()
    room:setCurrent(lord)
    lord.role = "hidden"

    local players = room.players
    local generals = room:getNGenerals(#players * generalNum)
    local req = Request:new(players, "AskForGeneral")
    req.timeout = self.room:getSettings("generalTimeout")
    table.shuffle(generals)
    for i, p in ipairs(players) do
      local arg = table.slice(generals, (i - 1) * generalNum + 1, i * generalNum + 1)
      req:setData(p, { arg, n })
      req:setDefaultReply(p, room:tableRandomPick(arg, n))
    end

    room:doBroadcastNotify("ShowToast", Fk:translate("chaos_intro"))

    req:ask()

    local selected = {}
    for _, p in ipairs(players) do
      local gs = req:getResult(p)
      local general = gs[1]
      local deputy = gs[2]
      room:setPlayerGeneral(p, general, true, true)
      room:setDeputyGeneral(p, deputy)
    end
    generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
    room:returnToGeneralPile(generals)

    room:askToChooseKingdom(players)
  end

  return chaos_logic
end

local function addGrain(room, player, num)
  room:addPlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_gain",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

local function removeGrain(room, player, num)
  room:removePlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_lose",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

local chaos_mode = fk.CreateGameMode{
  name = "chaos_mode",
  minPlayer = 4,
  maxPlayer = 10,
  rule = "#chaos_rule&",
  logic = chaos_getLogic,
  surrender_func = function(self, playedTime)
    return { {
      text = "chaos: left two alive",
      passed = #table.filter(Fk:currentRoom().players, function(p)
        return p.rest > 0 or not p.dead
      end) == 2
    } }
  end,
  winner_getter = function(self, victim)
    if not victim.surrendered and victim.rest > 0 then
      return ""
    end
    local room = victim.room
    local alive = table.filter(room.players, function(p)
      return not p.surrendered and not (p.dead and p.rest == 0)
    end)
    if #alive > 1 then return "" end
    return alive
  end,
  build_draw_pile = function(self)
    local draw, void = GameMode.buildDrawPile(self)
    local blacklist = {"god_salvation", "indulgence", "supply_shortage", "nullification"}
    local whitelist = {"time_flying", "substituting", "replace_with_a_fake", "wenhe_chaos"}

    if Fk:currentRoom():getSettings("modeChoice") == "chaos_mode_choice:custom" then
      table.insertTable(blacklist, {
        "lightning", "collateral", "amazing_grace",
      })
      table.insertTable(whitelist, {
        "forced_exchange", "armed_and_fed",
      })
    end

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
  end,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    if killer and not killer.dead then
      --事件2重赏，击杀奖励翻倍
      local doubled = room:getBanner("@[:]chaos_mode_event") == "generous_reward"
      if room:getSettings("modeChoice") == "chaos_mode_choice:custom" then
        if victim:getMark("@!!chaos_grain-noclear") > 0 then
          local n = victim:getMark("@!!chaos_grain-noclear")
          removeGrain(room, victim, n)
          addGrain(room, killer, doubled and n * 2 or n)
        end
        local choices = doubled and { "draw4", "recover2" } or { "draw2", "recover" }
        if killer.hp == killer.maxHp then
          table.remove(choices)
        end
        local choice = room:askToChoice(killer, {
          choices = choices,
          skill_name = "kill",
        })
        if choice:startsWith("draw") then
          killer:drawCards(doubled and 4 or 2, "kill")
        else
          if not killer.dead then
            room:recover({
              who = killer,
              num = doubled and 2 or 1
            })
          end
        end
      else
        room:changeMaxHp(killer, doubled and 2 or 1)
        if not killer.dead then
          killer:drawCards(doubled and 6 or 3, "kill")
        end
      end
    end
  end,
  friend_enemy_judge = function (self, targetOne, targetTwo)
    return targetOne == targetTwo
  end,
}

local W = require "ui_emu.preferences"
chaos_mode.ui_settings = {
  W.PreferenceGroup {
    title = "chaos_mode_rule",

    W.ComboRow {
      _settingsKey = "modeChoice",
      title = "chaos_mode_choice",
      model = {
        "chaos_mode_choice:custom",
        "chaos_mode_online",
      }
    },
  },
}

Fk:loadTranslationTable{
  ["chaos_mode"] = "文和乱武",
  [":chaos_mode"] = desc_chaos,
  ["chaos: left two alive"] = "仅剩两名角色存活",

  ["chaos_mode_rule"] = "文和乱武规则",
  ["chaos_mode_choice"] = "文和乱武模式选择",
  ["chaos_mode_choice:custom"] = "线下版本（文和乱武·战备）",
  ["chaos_mode_online"] = "线上版本",
}

return chaos_mode
