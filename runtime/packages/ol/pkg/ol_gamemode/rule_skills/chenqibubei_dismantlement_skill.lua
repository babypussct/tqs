local chenqibubei_dismantlement_skill = fk.CreateSkill {
  name = "chenqibubei_dismantlement_skill",
}
local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"
local U = require "packages.utility.utility"
local hasTalent = RougeUtil.hasTalent
local hasTalentStart = function(...)
  return #RougeUtil.hasTalentStart(...) > 0
end
local sendTalentLog = RougeUtil.sendTalentLog


RougeUtil:addBuffTalent { 3, "rouge_chenqibubei1" }
RougeUtil:addBuffTalent { 4, "rouge_chenqibubei2" }

Fk:loadTranslationTable {
  ["rouge_chenqibubei1"] = "趁其不备Ⅰ",
  [":rouge_chenqibubei1"] = "你使用【过河拆桥】时，至多弃置目标2张牌",
  ["rouge_chenqibubei2"] = "趁其不备Ⅱ",
  [":rouge_chenqibubei2"] = "你使用【过河拆桥】时，至多弃置目标3张牌",
  ["chenqibubei_dismantlement_skill"] = "趁其不备",
  ["#chenqibubei_dismantlement_skill"] = "选择一名区域内有牌的其他角色，你弃置其区域内的多张牌",
}


chenqibubei_dismantlement_skill:addEffect("cardskill", {
  name = "chenqibubei_dismantlement_skill",
  mute = true,
  prompt = "#chenqibubei_dismantlement_skill",
  can_use = function(self, player, card, extra_data)
    return not player:prohibitUse(card)
  end,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if from.dead or to.dead or to:isAllNude() then return end
    local num, skillName = 1, ""
    if hasTalent(from, "rouge_chenqibubei1") then
      num = 2
      skillName = "rouge_chenqibubei1"
    end
    if hasTalent(from, "rouge_chenqibubei2") then
      num = 3
      skillName = "rouge_chenqibubei2"
    end
    local cids = room:askToChooseCards(from, {
      target = to,
      min = 1,
      max = num,
      flag = "hej",
      skill_name = skillName
    })
    room:throwCard(cids, self.name, to, from)
  end
})

return chenqibubei_dismantlement_skill
