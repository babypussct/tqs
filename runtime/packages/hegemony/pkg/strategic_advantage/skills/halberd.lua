local halberdSkill = fk.CreateSkill{
  name = "#sa__halberd_skill",
  attached_equip = "sa__halberd",
}

halberdSkill:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(halberdSkill.name) and data.card.trueName == "slash" and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, ret = room:askToUseActiveSkill(player, {
      skill_name = "sa__halberd_active",
      cancelable = true,
      prompt = "#sa__halberd-ask",
      extra_data = {
        orig_tos = table.map(data.tos, Util.IdMapper),
        targets = table.map(data:getExtraTargets(), Util.IdMapper)
      }
    })
    if ret then
      event:setCostData(self, {tos = ret.targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/halberd")
    room:setEmotion(player, "./packages/standard_cards/image/anim/halberd")
    local tos = event:getCostData(self).tos
    data.extra_data = data.extra_data or {}
    data.extra_data.saHalberd = true
    room:sendLog{
      type = "#HalberdTargets",
      from = player.id,
      to = table.map(tos, Util.IdMapper),
      arg = "sa__halberd",
      card = Card:getIdList(data.card),
    }
    for _, p in ipairs(tos) do
      data:addTarget(p)
    end
  end
})
halberdSkill:addEffect(fk.CardEffectCancelledOut, {
  name = "#sa__halberd_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and (player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data.extra_data or {}).saHalberd
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    local use = e.data
    if #use.tos > 0 then
      room:sendLog{
        type = "#HalberdNullified",
        from = target.id,
        -- to = {player.id},
        arg = "sa__halberd",
        arg2 = data.card:toLogString(),
      }
      use.nullifiedTargets = use.tos
    end
  end,
})

Fk:loadTranslationTable{
  ["sa__halberd"] = "方天画戟",
  [":sa__halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br /><b>武器技能</b>：当你使用【杀】选择目标后，"..
  "可以令任意名势力各不相同、且与已选择的目标势力均不相同的角色和任意名没有势力的角色也成为目标，当此【杀】被【闪】抵消后，此【杀】对所有目标均无效。",
  ["#sa__halberd_skill"] = "方天画戟",
  ["#sa__halberd_targets"] = "方天画戟",
  ["#sa__halberd-ask"] = "方天画戟：令任意名势力各不相同且与已选择的目标势力均不相同的角色和任意名没有势力的角色也成为目标",
  ["#HalberdTargets"] = "%from 发动了〖%arg〗，令 %to 也成为 %card 的目标",
  ["#HalberdNullified"] = "由于〖%arg〗的效果，%from 对所有剩余目标使用的 %arg2 无效",
}

return halberdSkill
