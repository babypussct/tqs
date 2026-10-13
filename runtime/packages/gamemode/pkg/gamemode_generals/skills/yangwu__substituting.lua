local skill = fk.CreateSkill {
  name = "yangwu__substituting_skill",
}

Fk:loadTranslationTable{
  ["yangwu__substituting_skill"] = "李代桃僵",
  ["#yangwu__substituting-give"] = "请分配双方的手牌",
}

skill:addEffect("cardskill", {
  mute = true,
  prompt = "#substituting_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to.dead or from.dead or (to:isKongcheng() and from:isKongcheng()) then return end
    room:askToYiji(from, {
      cards = table.connect(from:getCardIds("h"), to:getCardIds("h")),
      targets = {from, to},
      skill_name = "substituting_skill",
      min_num = 0,
      max_num = from:getHandcardNum() + to:getHandcardNum(),
      prompt = "#yangwu__substituting-give",
      expand_pile = to:getCardIds("h"),
    })
  end,
})

return skill
