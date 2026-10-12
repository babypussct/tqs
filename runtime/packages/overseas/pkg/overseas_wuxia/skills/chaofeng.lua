local chaofeng = fk.CreateSkill {
  name = "os__chaofeng"
}

Fk:loadTranslationTable{
  ["os__chaofeng"] = "朝凤",
  [":os__chaofeng"] = "你可以将【杀】当【闪】、【闪】当任意【杀】使用或打出。每回合限两次，当你以此法使用的牌结算结束后，" ..
  "你可以与至多三名角色<a href='#JointPindianDesc'>共同拼点</a>，赢的角色视为对所有没赢的角色使用一张火【杀】。",

  ["#os__chaofeng"] = "朝凤：你可将【杀】当【闪】、【闪】当任意【杀】使用或打出",
  ["#os__chaofeng-ask"] = "朝凤：与至多三名角色共同拼点，赢的角色视为对没赢的角色使用火【杀】",

  ["$os__chaofeng1"] = "枪出惊百鸟，技现震诸雄。",
  ["$os__chaofeng2"] = "出如鸾凤高翱，收若百鸟归林。",
}

local U = require "packages.utility.utility"

chaofeng:addEffect("viewas", {
  pattern = "slash,jink",
  card_num = 1,
  prompt = "#os__chaofeng",
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    local vs_pattern = {
      max_num = 1,
      min_num = 1,
      pattern = "slash,jink",
    }
    if card_name then
      local trueName = table.remove(card_name:split("__"))
      if trueName == "slash" then
        vs_pattern.pattern = "jink"
      elseif trueName == "jink" then
        vs_pattern.pattern = "slash"
      end
    end
    return vs_pattern
  end,
  interaction_helper = function(self, player, selected_cards)
    local names = { "slash", "jink" }
    if selected_cards[1] then
      table.removeOne(names, Fk:getCardById(selected_cards[1]).trueName)
    end
    local all_names = table.filter(Fk:getAllCardNames("b"), function(name)
      local tn = table.remove(name:split("__"))
      return table.contains(names, tn)
    end)
    names = player:getViewAsCardNames(chaofeng.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    return Fk:cloneCard(choice, nil, nil, chaofeng.name, cards)
  end,
  enabled_at_response = function(self, player)
    return #player:getViewAsCardNames(chaofeng.name, {"slash", "jink"}) > 0
  end,
})

chaofeng:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaofeng.name) and
      table.contains(data.card.skillNames, chaofeng.name) and #Card:getIdList(data.card) == 1 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) < 2 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 3,
      prompt = "#os__chaofeng-ask",
      skill_name = chaofeng.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = chaofeng.name
    local room = player.room
    local targets = event:getCostData(self).tos ---@cast targets -nil
    local pd = U.jointPindian(player, targets, skillName)
    if pd.winner then
      table.insert(targets, player)
      table.removeOne(targets, pd.winner)
      room:useVirtualCard("fire__slash", nil, pd.winner, targets, skillName, true)
    end
  end,
})

return chaofeng
