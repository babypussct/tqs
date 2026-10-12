
local qiangzhi = fk.CreateSkill {
  name = "ol_ex__qiangzhi",
}

Fk:loadTranslationTable{
  ["ol_ex__qiangzhi"] = "强识",
  [":ol_ex__qiangzhi"] = "出牌阶段开始时，你可以观看一名其他角色的手牌并展示其中一张牌，然后你本阶段使用此类别的牌后可摸一张牌。",

  ["#ol_ex__qiangzhi-choose"] = "强识：观看并展示一名其他角色的一张手牌，你本阶段使用此类别的牌后，可以摸一张牌",
  ["@ol_ex__qiangzhi-phase"] = "强识",
  ["#ol_ex__qiangzhi-invoke"] = "强识：你可以摸一张牌",

  ["$ol_ex__qiangzhi1"] = "今观丞相之威，可比当年董卓英雄十倍。",
  ["$ol_ex__qiangzhi2"] = "丞相有情有义，吾等西川陋人岂敢比之？",
}

qiangzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
  return target == player and player:hasSkill(qiangzhi.name) and player.phase == Player.Play and
    table.find(player.room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = qiangzhi.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ol_ex__qiangzhi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = { card_data = { { to.general, to:getCardIds("h") } } },
      skill_name = qiangzhi.name,
    })
    local type = Fk:getCardById(card):getTypeString()
    to:showCards(card)
    if not player.dead then
      room:setPlayerMark(player, "@ol_ex__qiangzhi-phase", type)
    end
  end,
})

qiangzhi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
  return target == player and player.phase == Player.Play and
    data.card:getTypeString() == player:getMark("@ol_ex__qiangzhi-phase")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiangzhi.name,
      prompt = "#ol_ex__qiangzhi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qiangzhi.name)
  end,
})

local AI = Fk.Ltk.AI
qiangzhi:addAI(AI.reuse("qiangzhi", AI.InvokeStrategy))
qiangzhi:addAI(AI.reuse("qiangzhi", AI.ChoosePlayersStrategy))

return qiangzhi
