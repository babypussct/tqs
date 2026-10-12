local daozhuan = fk.CreateSkill {
  name = "daozhuan",
}

Fk:loadTranslationTable{
  ["daozhuan"] = "道转",
  [":daozhuan"] = "每回合限一次，当你需使用基本牌时（每轮每种牌名限一次），你可以将你或当前回合角色的一张牌置入弃牌堆，视为使用此牌。"..
  "若当前回合角色本次失去了牌，本技能本轮失效。",

  ["#daozhuan"] = "道转：将你或 %dest 的一张牌置入弃牌堆，视为使用基本牌",
  ["#daozhuan_self"] = "道转：将一张牌置入弃牌堆，视为使用基本牌",
  ["#daozhuan-ask"] = "道转：将你或当前回合角色的一张牌置入弃牌堆",

  ["$daozhuan1"] = "吾承天道法，闭其凶恶之路，开天太平之阶。",
  ["$daozhuan2"] = "幸欲报天地之功而得寿者，努力信道勿懈。",
  ["$daozhuan3"] = "不学无求贤，不耕无求收，子知之乎？",
  ["$daozhuan4"] = "哀哉！有志之士，早计早计，无负今言。",
}

Fk:addPoxiMethod{
  name = "daozhuan",
  prompt = "#daozhuan-ask",
  card_filter = function(to_select, selected, data)
    return #selected == 0
  end,
  feasible = function(selected)
    return #selected == 1
  end,
  default_choice = function (data, extra_data)
    return {data[1][2][1]}
  end,
}

daozhuan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player, selected_cards, selected)
    if Fk:currentRoom().current == player then
      return "#daozhuan_self"
    else
      return "#daozhuan::"..Fk:currentRoom().current.id
    end
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(daozhuan.name, all_names, nil, player:getTableMark("daozhuan-round"))
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_names = all_names}
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = daozhuan.name
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:addTableMarkIfNeed(player, "daozhuan-round", use.card.trueName)
    local card_data, extra_data, visible_data = {}, { prohibit = {} }, {}
    if room.current ~= player then
      if not room.current:isKongcheng() then
        table.insert(card_data, { room.current.general, room.current:getCardIds("h") })
        for _, id in ipairs(room.current:getCardIds("h")) do
          if not player:cardVisible(id) then
            visible_data[tostring(id)] = false
          end
        end
        if next(visible_data) == nil then visible_data = nil end
        extra_data.visible_data = visible_data
      end
      if #room.current:getCardIds("e") > 0 then
        table.insert(card_data, { Fk:translate(room.current.general).." ", room.current:getCardIds("e") })
      end
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player:getCardIds("h") })
      local cards = table.filter(player:getCardIds("h"), function(id)
        return player:prohibitDiscard(id)
      end)
      extra_data.prohibit = cards
    end
    if #player:getCardIds("e") > 0 then
      table.insert(card_data, { Fk:translate(player.general).." ", player:getCardIds("e") })
    end
    local result = room:askToPoxi(player, {
      poxi_type = daozhuan.name,
      data = card_data,
      cancelable = false,
      extra_data = extra_data,
    })
    local yes = table.contains(room.current:getCardIds("he"), result[1])
    room:moveCardTo(result, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, daozhuan.name, nil, true, player)
    if yes and not player.dead then
      room:invalidateSkill(player, daozhuan.name, "-round")
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(daozhuan.name) == 0 and not (player:isNude() and Fk:currentRoom().current:isNude())
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      player:usedSkillTimes(daozhuan.name) == 0 and
      not (player:isNude() and Fk:currentRoom().current:isNude()) and
      #player:getViewAsCardNames(daozhuan.name, Fk:getAllCardNames("b"), nil, player:getTableMark("daozhuan-round")) > 0
  end,
})

return daozhuan
