local zhifeng = fk.CreateSkill {
  name = "zhifeng",
}

Fk:loadTranslationTable{
  ["zhifeng"] = "猘锋",
  [":zhifeng"] = "每回合限X次（X为游戏人数），若你的手牌数：大于体力值，你可将至少一张黑色牌当不计入次数的【酒】使用；小于体力值，" ..
  "你可将一张红色牌当无距离限制的任意【杀】使用或打出，然后将手牌摸至体力上限；等于体力值，你可将至少一张牌当【决斗】对至多两名目标使用。",

  ["#zhifeng-analeptic"] = "猘锋：你可将至少一张黑色牌当不计入次数的【酒】使用",
  ["#zhifeng-duel"] = "猘锋：你可将至少一张牌当【决斗】对至多两名目标使用",
  ["#zhifeng-slash"] = "猘锋：你可将一张红色牌当无距离限制的【杀】使用或打出，然后将手牌摸至体力上限",

  ["$zhifeng1"] = "千里江东地，谁敢独槊相向！",
  ["$zhifeng2"] = "饮江为酿，看我醉挑山河！",
}

zhifeng:addEffect("viewas", {
  pattern = "analeptic,slash,duel",
  prompt = function(self, player)
    local prompt = "#zhifeng-analeptic"
    local handcardNum = player:getHandcardNum()
    if handcardNum == player.hp then
      prompt = "#zhifeng-duel"
    elseif handcardNum < player.hp then
      prompt = "#zhifeng-slash"
    end

    return prompt
  end,
  handly_pile = true,
  times = function(self, player)
    return #Fk:currentRoom().players - player:usedSkillTimes(zhifeng.name)
  end,
  filter_pattern = function(self, player, cardName)
    local vsPattern = {
      max_num = 999,
      min_num = 1,
      pattern = ".",
    }

    local handcardNum = player:getHandcardNum()
    if handcardNum > player.hp then
      vsPattern.pattern = ".|.|black"
    elseif handcardNum < player.hp then
      vsPattern.max_num = 1
      vsPattern.pattern = ".|.|red"
    end
    return vsPattern
  end,
  interaction_helper = function(self, player, selected_cards)
    if player:getHandcardNum() < player.hp then
      local slashes = { "slash" }
      table.insertTable(
        slashes,
        table.filter(Fk:getAllCardNames("b"), function(name) return name:endsWith("__slash") end)
      )
      local choices = player:getViewAsCardNames(zhifeng.name, slashes, selected_cards)
      return UI.CardNameBox{ choices = choices, all_choices = slashes }
    end
  end,
  view_as = function(self, player, cards)
    local handcardNum = player:getHandcardNum()
    if (handcardNum < player.hp and #cards ~= 1) or #cards < 1 then
      return
    end

    local card
    if handcardNum > player.hp then
      card = Fk:cloneCard("analeptic")
    elseif handcardNum == player.hp then
      card = Fk:cloneCard("duel")
    else
      if self.interaction.data == nil then
        return
      end

      card = Fk:cloneCard(self.interaction.data)
    end
    card.skillName = zhifeng.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    if use.card.name == "analeptic" then
      use.extraUse = true
    elseif use.card.trueName == "slash" then
      use.extra_data = use.extra_data or {}
      use.extra_data.zhifengSlash = true
    end
  end,
  after_use = function(self, player, use)
    if not (use.extra_data or {}).zhifengSlash then
      return
    end

    local drawNum = player.maxHp - player:getHandcardNum()
    if drawNum > 0 then
      player:drawCards(drawNum, zhifeng.name)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(zhifeng.name) < #Fk:currentRoom().players
  end,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(zhifeng.name) >= #Fk:currentRoom().players then
      return false
    end

    local judgeResponse = not response
    local handcardNum = player:getHandcardNum()
    local cardName = "analeptic"
    if handcardNum == player.hp then
      cardName = "duel"
    elseif handcardNum < player.hp then
      cardName = "slash"
      judgeResponse = true
    end

    return judgeResponse and #player:getViewAsCardNames(zhifeng.name, { cardName }) > 0
  end,
})

zhifeng:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and card.trueName == "slash" and table.contains(card.skillNames, zhifeng.name)
  end,
  extra_target_func = function(self, player, skill, card)
    if card and card.name == "duel" and table.contains(card.skillNames, zhifeng.name) then
      return 1
    end
  end,
})

return zhifeng
