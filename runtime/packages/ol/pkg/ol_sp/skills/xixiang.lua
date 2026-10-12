local xixiang = fk.CreateSkill{
  name = "xixiang",
  max_branches_use_time = {
    ["slash"] = {
      [Player.HistoryPhase] = 1
    },
    ["duel"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["xixiang"] = "西向",
  [":xixiang"] = "出牌阶段各限一次，你可以将至少X张牌当【杀】或【决斗】对一名角色使用（无距离次数限制，X为所有角色本回合使用基本牌数+1）。"..
  "此牌结算后，若其体力值：大于你的手牌数，你摸一张牌；大于你的体力值，你回复1点体力，然后获得其一张牌。",

  ["#xixiang"] = "西向：将至少%arg张牌当【杀】或【决斗】使用",
  ["#xixiang-prey"] = "西向：获得 %dest 一张牌",

  ["$xixiang1"] = "挥剑断浮云，诸君共西向！",
  ["$xixiang2"] = "西望故都，何忍君父辱于匹夫之手！",
}

xixiang:addEffect("viewas", {
  pattern = "slash,duel",
  anim_type = "offensive",
  prompt = function(self, player)
    return "#xixiang:::"..player:getMark("xixiang-turn") + 1
  end,
  filter_pattern = function(self, player, card_name)
    return {
      min_num = player:getMark("xixiang-turn") + 1,
      max_num = math.huge,
      pattern = ".",
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = { "slash", "duel" }
    local names = table.filter(all_names, function(name)
      return xixiang:withinBranchTimesLimit(player, name, Player.HistoryPhase)
    end)
    if #names == 0 then return end
    names = player:getViewAsCardNames(xixiang.name, names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil or #cards < player:getMark("xixiang-turn") + 1 then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, xixiang.name, cards)
  end,
  history_branch = function(self, player, data)
    return data.interaction_data
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    local data = { from = player, tos = table.simpleClone(use.tos) }
    use.extra_data = { xixiang_data = data }
  end,
  enabled_at_response = Util.FalseFunc,
}, { check_skill_limit = true })

xixiang:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xixiang.name) and
      data.extra_data and data.extra_data.xixiang_data and data.extra_data.xixiang_data.from == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = xixiang.name
    local tos = data.extra_data.xixiang_data.tos
    for _, p in ipairs(tos) do
      if not p.dead then
        if p.hp > player:getHandcardNum() then
          player:drawCards(1, skillName)
          if player.dead then return end
        end
        if not p.dead and p.hp > player.hp then
          if player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skillName = skillName,
            }
            if player.dead then return end
          end
          if not (p.dead or p:isNude()) then
            local card = room:askToChooseCard(player, {
              target = p,
              flag = "he",
              skill_name = skillName,
            })
            room:obtainCard(player, card, false, fk.ReasonPrey, player, skillName)
          end
        end
      end
    end
  end,
})

xixiang:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xixiang.name) and player.room:getCurrent() == player and data.card.type == Card.TypeBasic
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xixiang-turn", 1)
  end,
})

xixiang:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, xixiang.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, xixiang.name)
  end,
})

return xixiang
