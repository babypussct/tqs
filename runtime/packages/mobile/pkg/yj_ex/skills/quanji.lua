local quanji = fk.CreateSkill {
  name = "m_ex__quanji",
  derived_piles = "zhonghui_quan",
}

Fk:loadTranslationTable{
  ["m_ex__quanji"] = "权计",
  [":m_ex__quanji"] = "出牌阶段结束时，若你的手牌数大于你的体力值，或当你受到1点伤害后，你可以摸一张牌，"..
    "然后你将一张手牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”数）。",

  ["$m_ex__quanji1"] = "缓急不在一时，吾等慢慢来过。",
  ["$m_ex__quanji2"] = "善算轻重，权审其宜。",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, quanji.name)
    if not player:isKongcheng() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = quanji.name,
        prompt = "#quanji-ask",
        cancelable = false,
      })
      player:addToPile("zhonghui_quan", card, true, quanji.name)
    end
  end,
}

quanji:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getHandcardNum() > player.hp and
      player:hasSkill(quanji.name)
  end,
  on_use = spec.on_use,
})

quanji:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = spec.on_use,
})

quanji:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(quanji.name) then
      return #player:getPile("zhonghui_quan")
    else
      return 0
    end
  end,
})

local AI = Fk.Ltk.AI
quanji:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return quanji
