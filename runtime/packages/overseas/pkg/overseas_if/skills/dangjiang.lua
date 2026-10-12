local dangjiang = fk.CreateSkill {
  name = "os__dangjiang",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable {
  ["os__dangjiang"] = "荡疆",
  [":os__dangjiang"] = "转换技，阳：你可以将一张非伤害牌当【无中生有】使用；阴：你可以将一张非伤害牌当无距离限制的任意【杀】使用。" ..
  "若你以此法使用牌指定了未受伤角色为目标，你摸一张牌。",

  ["#os__dangjiang-yang"] = "荡疆：你可以将一张非伤害牌当【无中生有】使用，若目标未受伤，你摸一张牌",
  ["#os__dangjiang-yin"] = "荡疆：你可以将一张非伤害牌当无距离限制的任意【杀】使用，若目标未受伤，你摸一张牌",

  ["$os__dangjiang1"] = "霸王再世，亦难成吾这般功业！", -- 无中生有
  ["$os__dangjiang2"] = "拓宇开疆，四野当颂吾名！", -- 杀
}

dangjiang:addEffect("viewas", {
  mute = true,
  pattern = "slash,ex_nihilo",
  prompt = function (self, player, cards, targets)
    return "#os__dangjiang-" .. player:getSwitchSkillState(dangjiang.name, false, true)
  end,
  handly_pile = true,
  filter_pattern = function (self, player)
    local cards = table.filter(table.connect(player:getCardIds("he"), player:getHandlyIds()), function(c)
      return Fk:getCardById(c).damage_type == nil
    end)
    return {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    if player:getSwitchSkillState(dangjiang.name) == fk.SwitchYin then
      local all_names = table.filter(Fk:getAllCardNames("b"), function(name)
        return Fk:cloneCard(name).trueName == "slash"
      end)
      local names = player:getViewAsCardNames(dangjiang.name, all_names, selected_cards)
      return UI.CardNameBox{ choices = names, all_choices = all_names }
    end
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local name = player:getSwitchSkillState(dangjiang.name) == fk.SwitchYang and "ex_nihilo" or self.interaction.data
    if not name then return end
    local card = Fk:cloneCard(name, nil, nil, dangjiang.name, cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local slash = use.card.name == "slash"
    room:notifySkillInvoked(player, dangjiang.name, slash and "offensive" or "drawcard")
    player:broadcastSkillInvoke(dangjiang.name, slash and 2 or 1)
    use.extra_data = use.extra_data or {}
    use.extra_data.osDangjiangUser = player.id
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

dangjiang:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and (data.extra_data or {}).osDangjiangUser == player.id and
      data.firstTarget and table.find(data:getAllTargets(), function (to)
        return not to:isWounded()
      end)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, dangjiang.name)
  end,
})

dangjiang:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, dangjiang.name) and card and card.trueName == "slash"
  end,
})

return dangjiang
