local liangyuan = fk.CreateSkill{
  name = "liangyuan",
  max_branches_use_time = {
    ["analeptic"] = {
      [Player.HistoryRound] = 1
    },
    ["peach"] = {
      [Player.HistoryRound] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["liangyuan"] = "良缘",
  [":liangyuan"] = "每轮各限一次，你可以将全场所有「灵杉」当【酒】、「玉树」当【桃】使用。",

  ["#liangyuan"] = "良缘：将全场所有「灵杉」当【酒】、「玉树」当【桃】使用",
  ["liangyuan_peach"] = "将「灵杉」当【桃】使用",
  ["liangyuan_analeptic"] = "将「玉树」当【酒】使用",

  ["$liangyuan1"] = "千古奇遇，共剪西窗。",
  ["$liangyuan2"] = "金玉良缘，来日方长。",
}

liangyuan:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach,analeptic",
  prompt = "#liangyuan",
  interaction = function(self, player)
    local all_names, piles, names = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}, {}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if liangyuan:withinBranchTimesLimit(player, name, Player.HistoryRound) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          table.insertIfNeed(names, "liangyuan_" .. name)
        end
      end
    end
    return UI.OptionBox {
      options = names,
      all_options = { "liangyuan_analeptic", "liangyuan_peach" },
      direct_send = true
    }
  end,
  filter_pattern = function(self, player, card_name)
    local cards = {}
    if card_name == "peach" then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertTable(cards, p:getPile("huamu_yushu"))
      end
    else
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertTable(cards, p:getPile("huamu_lingshan"))
      end
    end
    local x = #cards
    if #cards > 0 then
      return {
        max_num = x,
        min_num = x,
        pattern = "",
        subcards = cards
      }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local name = self.interaction.data
    if name == nil then return end
    name = name:sub(11)
    local subcards = {}
    local pile_name = name == "peach" and "huamu_yushu" or "huamu_lingshan"
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertTable(subcards, p:getPile(pile_name))
    end
    if #subcards == 0 then return nil end
    local card = Fk:cloneCard(name)
    card.skillName = liangyuan.name
    card:addSubcards(subcards)
    return card
  end,
  history_branch = function(self, player, data)
    return data.interaction_data:sub(11)
  end,
  enabled_at_play = function(self, player)
    local all_names, piles = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if liangyuan:withinBranchTimesLimit(player, name, Player.HistoryRound) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local all_names, piles = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if liangyuan:withinBranchTimesLimit(player, name, Player.HistoryRound) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          return true
        end
      end
    end
  end,
}, { check_skill_limit = true })

return liangyuan
