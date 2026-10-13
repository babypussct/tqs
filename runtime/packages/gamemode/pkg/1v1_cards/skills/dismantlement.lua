local skill = fk.CreateSkill {
  name = "v11__dismantlement_skill",
}

skill:addEffect("cardskill", {
  prompt = "#v11__dismantlement_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if from.dead or to.dead or to:isNude() then return end
    local handcards = to:getCardIds("h")
    local choices = {}
    if #to:getCardIds("e") > 0 then
      table.insert(choices, "$Equip")
    end
    if #handcards > 0 then
      table.insert(choices, "$Hand")
    end
    local flag = "e"
    if room:askToChoice(from, {
      choices = choices,
      skill_name = skill.name,
    }) == "$Hand" then
      flag = { card_data = { { to.general, handcards } } }
    end
    local cid = room:askToChooseCard(from, {
      target = to,
      flag = flag,
      skill_name = skill.name,
    })
    room:throwCard(cid, skill.name, to, from)
  end,
})

return skill
