local skill = fk.CreateSkill {
  name = "abandoning_armor_skill",
}

Fk:loadTranslationTable{
  ["abandoning_armor_offensive"] = "弃置手牌区和装备区里所有的武器和进攻坐骑",
  ["abandoning_armor_defensive"] = "弃置手牌区和装备区里所有的防具和防御坐骑",
}

skill:addEffect("cardskill", {
  prompt = "#abandoning_armor_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and #to_select:getCardIds("e") > 0
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    if to.dead then return end
    local all_choices = {"abandoning_armor_offensive", "abandoning_armor_defensive"}
    local choices = {}
    local x, y = {}, {}
    local cards = to:getCardIds("he")
    for _, cid in ipairs(cards) do
      if not to:prohibitDiscard(cid) then
        local subtype = Fk:getCardById(cid).sub_type
        if subtype == Card.SubtypeWeapon or subtype == Card.SubtypeOffensiveRide then
          table.insert(x, cid)
        elseif subtype == Card.SubtypeArmor or subtype == Card.SubtypeDefensiveRide then
          table.insert(y, cid)
        end
      end
    end
    if #x > 0 then table.insert(choices, "abandoning_armor_offensive") end
    if #y > 0 then table.insert(choices, "abandoning_armor_defensive") end
    if #choices == 0 then return end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = skill.name,
      all_choices = all_choices,
    })
    room:throwCard(choice == "abandoning_armor_offensive" and x or y, skill.name, to, to)
  end,
})

return skill
