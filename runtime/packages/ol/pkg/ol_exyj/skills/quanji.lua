
local quanji = fk.CreateSkill {
  name = "ol_ex__quanji",
  derived_piles = "zhonghui_quan",
}

Fk:loadTranslationTable{
  ["ol_ex__quanji"] = "权计",
  [":ol_ex__quanji"] = "当你造成或受到1点伤害后，你可以摸一张牌，然后令当前回合角色将一张手牌置于你的武将牌上，称为“权”；"..
  "每有一张“权”，你的手牌上限便+1。",

  ["#ol_ex__quanji-ask"] = "权计：请将一张手牌置为 %src 的“权”",

  ["$ol_ex__quanji1"] = "",
  ["$ol_ex__quanji2"] = "",
}

local spec = {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, quanji.name)
    local current = room:getCurrent()
    if not current or current:isKongcheng() or not player:hasSkill(quanji.name, true) then return end
    room:doIndicate(player, { current })
    local card = room:askToCards(current, {
      skill_name = quanji.name,
      include_equip = false,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__quanji-ask:"..player.id,
      cancelable = false,
    })
    player:addToPile("zhonghui_quan", card, true, quanji.name)
  end,
}
quanji:addEffect(fk.Damage, spec)
quanji:addEffect(fk.Damaged, spec)

quanji:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(quanji.name) then
      return #player:getPile("zhonghui_quan")
    end
  end,
})

quanji:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return quanji
