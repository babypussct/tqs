local quanji = fk.CreateSkill {
  name = "ol_heg__quanji",
  derived_piles = "ol_heg__zhonghui_quan",
}

Fk:loadTranslationTable{
  ["ol_heg__quanji"] = "权计",
  [":ol_heg__quanji"] = "当你受到伤害后，你可以摸一张牌，然后将一张牌置于武将牌上，称为“权”。",

  ["ol_heg__zhonghui_quan"] = "权",
  ["#ol_heg__quanji-ask"] = "权计：将一张牌置为“权”",

  ["$ol_heg__quanji1"] = "这仇，我记下了。",
  ["$ol_heg__quanji2"] = "先让你得意几天。",
}

quanji:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, quanji.name)
    if player:isNude() or player.dead then return end
    local card = room:askToCards(player, {
      skill_name = quanji.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_heg__quanji-ask",
      cancelable = false,
    })
    player:addToPile("ol_heg__zhonghui_quan", card, true, quanji.name)
  end,
})

return quanji
