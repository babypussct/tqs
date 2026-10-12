local qiaoshi = fk.CreateSkill {
  name = "ol_ex__qiaoshi",
}

Fk:loadTranslationTable{
  ["ol_ex__qiaoshi"] = "樵拾",
  [":ol_ex__qiaoshi"] = "每个结束阶段，你可以与当前回合角色各摸一张牌，然后若其与你手牌数不相等，此技能本轮失效。",

  ["#ol_ex__qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",

  ["$ol_ex__qiaoshi1"] = "穿林觅干柴，满目松竹梅兰。",
  ["$ol_ex__qiaoshi2"] = "晚凉抬担归，艳艳野花插鬓。",
}

qiaoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiaoshi.name) and target.phase == Player.Finish and
      not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qiaoshi.name,
      prompt = "#ol_ex__qiaoshi-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, qiaoshi.name)
    if not player.dead then
      player:drawCards(1, qiaoshi.name)
    end
    if not player.dead and player:getHandcardNum() ~= target:getHandcardNum() then
      player.room:invalidateSkill(player, qiaoshi.name, "-round")
    end
  end,
})

local AI = Fk.Ltk.AI
qiaoshi:addAI(AI.reuse("wangxi", AI.InvokeStrategy))

return qiaoshi
