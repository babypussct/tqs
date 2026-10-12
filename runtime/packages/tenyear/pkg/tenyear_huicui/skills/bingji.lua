local bingji = fk.CreateSkill {
  name = "bingji",
}

Fk:loadTranslationTable{
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】"..
  "（有距离限制且不计入次数）或一张【桃】。",

  ["#bingji"] = "秉纪：展示所有手牌，视为对一名其他角色使用【杀】或【桃】",
  ["@bingji-phase"] = "秉纪",
  ["#bingji-use"] = "秉纪：视为对一名其他角色使用一张【杀】或【桃】",

  ["$bingji1"] = "权其轻重，而后施令。",
  ["$bingji2"] = "罪而后赦，以立恩威。",
}

bingji:addAuxActiveSkill("bingji_viewas", {
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    local names = { "slash", "peach" }
    return UI.CardNameBox {
      choices = table.filter(names, function(name)
        return not player:prohibitUse(Fk:cloneCard(name, Card.NoSuit, 0, bingji.name))
      end),
      all_choices = names
    }
  end,
  fix_targets = function(self, player, selected_cards, _, extra_data)
    --UI only，传空表可以让photo不变暗
    if self.interaction.data == nil then return {} end
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player and self.interaction.data then
      local card = Fk:cloneCard(self.interaction.data, Card.NoSuit, 0, bingji.name)
      return player:canUseTo(card, to_select, { bypass_distances = false, bypass_times = true })
    end
  end,
})

bingji:addEffect("active", {
  anim_type = "control",
  prompt = "#bingji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and
      not table.contains(player:getTableMark("@bingji-phase"), Fk:getCardById(player:getCardIds("h")[1]):getSuitString(true)) and
      table.every(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(player:getCardIds("h")[1]))
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "@bingji-phase", Fk:getCardById(player:getCardIds("h")[1]):getSuitString(true))
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    local others = room:getOtherPlayers(player)
    if #others == 0 then return end
    local default_name, to
    for _, name in ipairs({ "slash", "peach" }) do
      local card = Fk:cloneCard(name, Card.NoSuit, 0, bingji.name)
      to = table.find(others, function(p)
        return player:canUseTo(card, p, { bypass_distances = false, bypass_times = true })
      end)
      if to then
        default_name = name
        break
      end
    end
    if not (default_name and to) then return end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "bingji_viewas",
      prompt = "#bingji-use",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {
        interaction = default_name,
        targets = { to }
      }
    end
    room:useVirtualCard(dat.interaction, nil, player, dat.targets, bingji.name, true)
  end
})

return bingji
