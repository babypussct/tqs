local jibing = fk.CreateSkill {
  name = "jibing",
  derived_piles = "mayuanyi_bing",
}

Fk:loadTranslationTable{
  ["jibing"] = "集兵",
  [":jibing"] = "摸牌阶段开始时，若你的“兵”数少于X（X为场上势力数），你可以放弃摸牌，改为将牌堆顶两张牌置于你的武将牌上，称为“兵”。"..
  "你可以将一张“兵”当做普通【杀】或【闪】使用或打出。",

  ["#jibing"] = "集兵：你可以将一张“兵”当【杀】或【闪】使用或打出",
  ["#jibing-invoke"] = "集兵：是否放弃摸牌，改为获得两张“兵”？",
  ["mayuanyi_bing"] = "兵",

  ["$jibing1"] = "集荆、扬精兵，而后共举大义！",
  ["$jibing2"] = "教众快快集合，不可误了大事！",
}

jibing:addEffect("viewas", {
  pattern = "slash,jink",
  expand_pile = "mayuanyi_bing",
  prompt = "#jibing",
  interaction = function(self, player)
    local all_names = { "slash", "jink" }
    local names = player:getViewAsCardNames(jibing.name, all_names)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|mayuanyi_bing",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = jibing.name
    card:addSubcard(cards[1])
    return card
  end,
})

jibing:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jibing.name) and player.phase == Player.Draw then
      local kingdoms = {}
      for _, p in ipairs(player.room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #player:getPile("mayuanyi_bing") < #kingdoms
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = jibing.name, prompt = "#jibing-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    data.phase_end = true
    player:addToPile("mayuanyi_bing", player.room:getNCards(2), false, jibing.name)
  end,
})

return jibing
