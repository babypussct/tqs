local quanji = fk.CreateSkill {
  name = "ld__quanji",
  derived_piles = "ld__zhonghui_power",
}

Fk:loadTranslationTable {
  ["ld__quanji"] = "权计",
  [":ld__quanji"] = "每回合各限一次，当你受到伤害或造成伤害后，你可摸一张牌，然后将一张牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”的数量）。",

  ["#ld__quanji-push"] = "权计：将一张牌置于武将牌上（称为“权”）",
  ["ld__zhonghui_power"] = "权",

  ["$ld__quanji1"] = "不露圭角，择时而发！",
  ["$ld__quanji2"] = "晦养厚积，乘势而起！",
}

quanji:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(quanji.name) or player.dead then return false end
    return player:getMark("_ld__quanji_damaged-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(quanji.name)
    room:setPlayerMark(player, "_ld__quanji_damaged-turn", 1)
    room:notifySkillInvoked(player, quanji.name, "masochism")
    player:drawCards(1, quanji.name)
    if not player:isNude() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = quanji.name,
        cancelable = false,
        prompt = "#ld__quanji-push",
      })
      player:addToPile("ld__zhonghui_power", card, true, quanji.name)
    end
  end,
})

quanji:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(quanji.name) or player.dead then return false end
    return player:getMark("_ld__quanji_damage-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(quanji.name)
    room:setPlayerMark(player, "_ld__quanji_damage-turn", 1)
    room:notifySkillInvoked(player, quanji.name, "drawcard")
    player:drawCards(1, quanji.name)
    if not player:isNude() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = quanji.name,
        cancelable = false,
        prompt = "#ld__quanji-push",
      })
      player:addToPile("ld__zhonghui_power", card, true, quanji.name)
    end
  end,
})

quanji:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:hasSkill(quanji.name) and #player:getPile("ld__zhonghui_power") or 0
  end,
})

return quanji
