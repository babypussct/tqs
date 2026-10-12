local yigui = fk.CreateSkill {
  name = "ld__yigui",
}

Fk:loadTranslationTable {
  ["ld__yigui"] = "役鬼",
  [":ld__yigui"] = "当你首次明置此武将牌后，你将两张未加入游戏的武将牌扣置于武将牌上，称为“魂”；" ..
  "每回合每种牌名限一次，你可以移去一张“魂”，视为使用一张基本牌或普通锦囊牌，此牌只能指定与此“魂”势力相同或未确定势力的角色为目标。",
  ["@[private]&ld__hun"] = "魂",
  ["#ld__yigui-use"] = "%from 移去“魂”  %arg ，视为使用 %arg2",
  ["#ld__yigui-show"] = "役鬼",
  ["ld__yigui-chooce"] = "请选择",
  ["@$ld__yigui-turn"] = "役鬼",

  ["$ld__yigui1"] = "百鬼众魅，自缚见形。",
  ["$ld__yigui2"] = "来去无踪，众谓诡异。",
}

local U = require "packages.utility.utility"
local H = require "packages.hegemony.util"

---从牌堆获取魂
---@param player ServerPlayer
---@param n integer
local function GetHuashen(player, n)
  local room = player.room
  local generals = room:findGenerals(function() return true end, n)
  local mark = U.getPrivateMark(player, "&ld__hun")
  table.insertTableIfNeed(mark, generals)
  U.setPrivateMark(player, "&ld__hun", mark)
  if #player:getTableMark("ld__yigui_cards") == 0 then
    room:setPlayerMark(player, "ld__yigui_cards", room:getUniversalCards("bt"))
  end
end

---获取魂的合法目标
---@param to Player
---@param name string
local function canbeTargetedbySoul(to, name)
  local kingdoms, general = {}, Fk.generals[name]
  if general then
    table.insertIfNeed(kingdoms, general.kingdom)
    if general.subkingdom then
      table.insertIfNeed(kingdoms, general.subkingdom)
    end
  end
  local tokingdom = to.kingdom
  if tokingdom == "wild" and to:getMark("hasShownMainGeneral") == 0 then   --如果野人没亮过主将,按照原势力
    tokingdom = to:getMark("__heg_init_kingdom")
  end
  return tokingdom == "unknown" or table.contains(kingdoms, tokingdom)
end

---获取可用的魂
---@param player Player
---@return string[]
local function getAvailableSoul(player)
  local souls = U.getPrivateMark(player, "&ld__hun")
  if #souls == 0 then return {} end
  local players, availables = {}, {}
  local extra_data = player:getTableMark("ld__yigui_extra_data")
  if extra_data.fix_targets then
    table.insertTableIfNeed(players, extra_data.fix_targets)
  elseif extra_data.must_targets then
    table.insertTableIfNeed(players, extra_data.must_targets)
  elseif extra_data.exclusive_targets then
    table.insertTableIfNeed(players, extra_data.exclusive_targets)
  elseif extra_data.include_targets then
    table.insertTableIfNeed(players, extra_data.include_targets)
  end
  if #players == 0 then
    players = Fk.currentRoom(player).alive_players
  else
    players = table.map(players, Util.Id2PlayerMapper)
  end
  for _, s in ipairs(souls) do
    if table.find(players, function(p) return canbeTargetedbySoul(p, s) end) then
      table.insert(availables, s)
    end
  end
  return availables
end

---获取可以印的虚拟牌
---@param player Player
---@param skill_name string
---@param card_names? string[]
---@param souls? string[]
---@return string[]
local function getAvailableYiguiCard(player, skill_name, card_names, souls)
  souls = souls or getAvailableSoul(player)
  card_names = card_names or
  table.map(player:getTableMark("ld__yigui_cards"), function(id) return Fk:getCardById(id).name end)
  if #card_names == 0 then return {} end
  local ban_cards = player:getTableMark("ld__yigui_useds-turn")
  table.insertTableIfNeed(ban_cards, { "jink", "nullification", "heg__nullification" })
  local extra_data = player:getTableMark("ld__yigui_extra_data")
  local names = {}
  for _, name in ipairs(card_names) do
    local card = Fk:cloneCard(name)
    if (Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(card))
        and not table.contains(ban_cards, card.trueName) then
      card.skillName = skill_name
      for _, soul in ipairs(souls) do
        card:setMark("ld__yigui", soul)
        if player:canUse(card, extra_data) and not player:prohibitUse(card) then
          local min_target = card.skill:getMinTargetNum(player)
          if min_target > 0 then
            for _, p in pairs(Fk.currentRoom(player).alive_players) do
              if card.skill:targetFilter(player, p, {}, {}, card, extra_data) then
                table.insertIfNeed(names, name)
                goto continue
              end
            end
          else
            table.insertIfNeed(names, name)
            goto continue
          end
        end
      end
    end
    ::continue::
  end
  return names
end

--印牌主体
yigui:addEffect("viewas", {
  mute = true,
  pattern = ".|.|.|.|.|basic,trick",
  expand_pile = function(self, player)
    return player:getTableMark("ld__yigui_cards")
  end,
  interaction = function(self, player)
    local souls = U.getPrivateMark(player, "&ld__hun")
    local availables = getAvailableSoul(player)
    if #availables == 0 then return end
    return H.GeneralCardNameBox { choices = availables, all_choices = souls, default_choice = "ld__yigui-chooce" }
  end,
  card_filter = function(self, player, to_select, selected)
    if not self.interaction.data or self.interaction.data == "ld__yigui-chooce" then return false end
    if #selected > 0 or not table.contains(player:getTableMark("ld__yigui_cards"), to_select) then return false end
    local name = Fk:getCardById(to_select).name
    local cardnames = getAvailableYiguiCard(player, yigui.name, { name }, { self.interaction.data })
    return table.contains(cardnames, name)
  end,
  before_use = function(self, player, use)
    local room = player.room
    local marke = {}
    table.insert(marke, use.card.trueName)
    room:addTableMark(player, "@$ld__yigui-turn", marke)
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or not self.interaction.data or self.interaction.data == "ld__yigui-chooce" then return end
    local name = Fk:getCardById(cards[1]).name
    local card = Fk:cloneCard(name)
    card.skillName = yigui.name
    card:setMark("ld__yigui", self.interaction.data)
    return card
  end,
  enabled_at_play = function(self, player)
    return #getAvailableSoul(player) > 0
  end,
  enabled_at_response = function(self, player, response)
    return #getAvailableSoul(player) > 0 and not response and #getAvailableYiguiCard(player, yigui.name) > 0
  end,
})

--首次明置武将得魂
yigui:addEffect(fk.GeneralRevealed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yigui.name) or player:getMark("ld__yigui_show") > 0 then return false end
    for _, v in pairs(data) do
      if table.contains(Fk.generals[v]:getSkillNameList(), yigui.name) then return true end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "ld__yigui_show", 1)
    GetHuashen(player, 2)
  end,
})

yigui:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    if #U.getPrivateMark(player, "&ld__hun") == 0 then return false end
    return data.user == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ld__yigui_extra_data", data.afterRequest and 0 or data.extraData)
  end,
  on_lose = function(self, player, is_death)
    local room = player.room
    room:returnToGeneralPile(U.getPrivateMark(player, "&ld__hun"))
    room:setPlayerMark(player, "@[private]&ld__hun", 0)
  end,
})

yigui:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if #U.getPrivateMark(player, "&ld__hun") == 0 then return false end
    return player == target and table.contains(data.card.skillNames, yigui.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, yigui.name)
    player:broadcastSkillInvoke(yigui.name)
    room:addTableMark(player, "ld__yigui_useds-turn", data.card.trueName)
    local mark = U.getPrivateMark(player, "&ld__hun")
    table.removeOne(mark, data.card:getMark("ld__yigui"))
    room:returnToGeneralPile({ data.card:getMark("ld__yigui") })
    if #mark == 0 then
      room:setPlayerMark(player, "@[private]&ld__hun", 0)
    else
      U.setPrivateMark(player, "&ld__hun", mark)
    end
    room:sendLog {
      type = "#ld__yigui-use",
      from = player.id,
      arg = data.card:getMark("ld__yigui"),
      arg2 = data.card.name,
      toast = true,
    }
    data.extra_data = data.extra_data or {}
    data.extra_data.ce_hc__yigui = data.card:getMark("ld__yigui")       -- 往extra_data里备份一份魂的信息，防止扇子杀变火杀后信息丢失
  end,
  on_lose = function(self, player, is_death)
    local room = player.room
    room:returnToGeneralPile(U.getPrivateMark(player, "&ld__hun"))
    room:setPlayerMark(player, "@[private]&ld__hun", 0)
  end,
})

--排除目标
yigui:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if card and table.contains(card.skillNames, yigui.name) then
      local general = card:getMark("ld__yigui")
      if not general then     -- 丢失魂信息则寻找备用信息
        if RoomInstance then
          local logic = RoomInstance.logic
          local event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
          if event then
            local use = event.data
            if table.contains(use.card.skillNames, yigui.name) and use.card.name == card.name then
              use.extra_data = use.extra_data or {}
              general = use.extra_data.ce_hc__yigui
            end
          end
        end
      end
      return general and not canbeTargetedbySoul(to, general)
    end
  end,
})

return yigui
