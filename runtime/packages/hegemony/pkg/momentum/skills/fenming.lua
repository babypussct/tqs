local fenming = fk.CreateSkill{
  name = "fenming",
}

Fk:loadTranslationTable{
  ["fenming"] = "奋命",
  [":fenming"]=  "当你受到伤害后，若你处于横置状态，你可以弃置所有处于横置状态角色的各一张牌。",

  ["$fenming1"] = "东吴男儿，岂是贪生怕死之辈？",
  ["$fenming2"] = "不惜性命，也要保主公周全！",
}

fenming:addEffect(fk.Damaged, {
  anim_type = 'control',
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenming.name) and player.chained
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.chained and not p:isNude() and p:isAlive() and player:isAlive() then
        if p == player then
          local canDiscard = table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(id) end)
          if canDiscard then
            room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = fenming.name})
          end
        else
          local c = room:askToChooseCard(player, {target = p, flag = "he", skill_name = fenming.name})
          room:throwCard(c, fenming.name, p, player)
        end
      end
    end
  end,
})

return fenming
