local lucun = fk.CreateSkill{
  name = "lucun",
  derived_piles = "olmou__zhangrang_lu",
  max_branches_use_time = {
    ["basic"] = {
      [Player.HistoryRound] = 1
    },
    ["trick"] = {
      [Player.HistoryRound] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["lucun"] = "赂存",
  [":lucun"] = "每轮各限一次，你可以视为使用一张有目标的基本牌或普通锦囊牌（未以此法使用过），"..
    "然后目标中手牌最多的随机一名角色将一张手牌置于你的武将牌上，称为“赂”。"..
    "每个回合结束时，你随机移去一张“赂”，然后摸一张牌。",

  ["#lucun"] = "赂存：视为使用一张基本牌或普通锦囊牌，然后令手牌最多的目标角色放置一张手牌",
  ["#lucun-push"] = "赂存：将一张手牌置为 %src 的“赂”",

  ["olmou__zhangrang_lu"] = "赂",

  ["$lucun1"] = "汉家长城？老糊涂，这殿上哪来的什么长城！",
  ["$lucun2"] = "入物者补官，出货者罪除，咱家向来公正。",
  ["$lucun3"] = "饰貂带玉，配绶怀金，今日之贵皆赖帝恩。",
  ["$lucun4"] = "手握王爵，口含天宪，今非复廷巷小宦。",
  ["$lucun5"] = "头戴进贤，腰配绶带，哈哈，好一个狗官。",
  ["$lucun6"] = "啧啧啧~百里奚才值五张羊皮，汝这庸奴要什么钱？",
}

lucun:addEffect("viewas", {
  pattern = "^(jink,nullification)",
  prompt = "#lucun",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local all_names = {}
    if lucun:withinBranchTimesLimit(player, "basic", Player.HistoryRound) then
      table.insertTable(all_names, Fk:getAllCardNames("b"))
    end
    if lucun:withinBranchTimesLimit(player, "trick", Player.HistoryRound) then
      table.insertTable(all_names, Fk:getAllCardNames("t"))
    end
    local names = player:getViewAsCardNames(lucun.name, all_names, {}, player:getTableMark(lucun.name))
    names = table.filter(names, function(name)
      return not Fk:cloneCard(name).is_passive
    end)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, lucun.name)
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, lucun.name, use.card.trueName)
    player:addSkillBranchUseHistory(lucun.name, use.card:getTypeString(), 1)
  end,
  after_use = function(self, player, use)
    if player.dead then return end
    local room = player.room
    local tos = table.filter(use.tos, function(p)
      return table.every(use.tos, function(p2)
        return p:getHandcardNum() >= p2:getHandcardNum()
      end) and not p.dead
    end)
    if #tos == 0 or tos[1]:isKongcheng() then return end
    local to = room:tableRandomPick(tos)
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = lucun.name,
      cancelable = false,
      prompt = "#lucun-push:" .. player.id,
    })
    player:addToPile("olmou__zhangrang_lu", card, true, lucun.name, to)
  end,
  enabled_at_play = function(self, player)
    return lucun:withinBranchTimesLimit(player, "basic", Player.HistoryRound) or
      lucun:withinBranchTimesLimit(player, "trick", Player.HistoryRound)
  end,
  enabled_at_response = function(self, player, response)
    if not response then
      if lucun:withinBranchTimesLimit(player, "basic", Player.HistoryRound) and
        #player:getViewAsCardNames(lucun.name, Fk:getAllCardNames("b"), nil, player:getTableMark(lucun.name)) > 0 then
        return true
      end
      if lucun:withinBranchTimesLimit(player, "trick", Player.HistoryRound) and
        #player:getViewAsCardNames(lucun.name, Fk:getAllCardNames("t"), nil, player:getTableMark(lucun.name)) > 0 then
        return true
      end
    end
  end,
  enabled_at_nullification = Util.FalseFunc,
})

lucun:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lucun.name) and #player:getPile("olmou__zhangrang_lu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:tableRandomPick(player:getPile("olmou__zhangrang_lu"))
    room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lucun.name, nil, true, player)
    if not player.dead then
      player:drawCards(1, lucun.name)
    end
  end,
})

lucun:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, lucun.name, 0)
end)

return lucun
