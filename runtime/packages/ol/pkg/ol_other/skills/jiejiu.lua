local jiejiu = fk.CreateSkill{
  name = "jiejiu",
  tags = { Skill.Compulsory },
  related_skills = { "lijian" },
}

Fk:loadTranslationTable{
  ["jiejiu"] = "戒酒",
  [":jiejiu"] = "锁定技，你的【酒】仅能当其他基本牌使用。游戏开始时，将其他女性角色武将牌上随机一个技能替换为〖离间〗。",

  ["#jiejiu"] = "戒酒：仅能将【酒】当其他基本牌使用",

  ["$jiejiu"] = "我被酒色所伤，竟然如此憔悴。自今日始，戒酒！",
}

jiejiu:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#jiejiu",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = "analeptic",
  },
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(jiejiu.name, all_names, selected_cards, { "analeptic" })
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, jiejiu.name, cards)
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
jiejiu:addEffect(fk.GameStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiejiu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isFemale() then
        local skills = Fk.generals[p.general]:getSkillNameList(true)
        if #skills > 0 then
          room:handleAddLoseSkills(p, "lijian|-"..room:tableRandomPick(skills))
        end
      end
    end
  end,
})
jiejiu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not player:hasSkill(jiejiu.name) or not card or card.trueName ~= "analeptic" or #card.skillNames > 0 then return end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getHandlyIds(), id)
    end)
  end,
})

return jiejiu
