
local fuyu = fk.CreateSkill {
  name = "fuyu",
}

Fk:loadTranslationTable{
  ["fuyu"] = "负隅",
  [":fuyu"] = "每回合各限一次，当你成为其他角色使用基本牌或普通锦囊牌的唯一目标时，或你使用基本牌或普通锦囊牌指定其他角色为唯一目标时，"..
  "你可以与其拼点，若此牌使用者：赢，此牌额外结算一次；没赢，此牌无效。若你的拼点结果与上一次发动此技能时相同，你摸两张牌。",

  ["#fuyu1-invoke"] = "负隅：你可以与 %dest 拼点，若你赢，此牌额外结算一次；若没赢，此牌无效",
  ["#fuyu2-invoke"] = "负隅：你可以与 %dest 拼点，若其赢，此牌额外结算一次；若其没赢，此牌无效",

  ["$fuyu1"] = "吾为汉吏，当保城安民，岂可避之。",
  ["$fuyu2"] = "吾上能驰戈、下可走马，何言力不能拒？",
  ["$fuyu3"] = "吾等有地势之利，量孙策攻之不得。",
  ["$fuyu4"] = "此乃朝廷疆土，吾必以死守之。",
}

fuyu:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyu.name) and
      data.to ~= player and data:isOnlyTarget(data.to) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:canPindian(data.to) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = fuyu.name,
      prompt = "#fuyu1-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({ data.to }, fuyu.name)
    if pindian.results[data.to].winner == player then
      if not player.dead then
        if player:getMark(fuyu.name) == "win" then
          player:drawCards(2, fuyu.name)
        end
        if not player.dead then
          room:setPlayerMark(player, fuyu.name, "win")
        end
      end
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    else
      if not player.dead then
        if player:getMark(fuyu.name) == "lose" then
          player:drawCards(2, fuyu.name)
        end
        if not player.dead then
          room:setPlayerMark(player, fuyu.name, "lose")
        end
      end
      data.nullified = true
    end
  end,
})

fuyu:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyu.name) and
      data.from ~= player and data:isOnlyTarget(player) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:canPindian(data.from) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = fuyu.name,
      prompt = "#fuyu2-invoke::"..data.from.id,
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({ data.from }, fuyu.name)
    if pindian.results[data.from].winner == data.from then
      if not player.dead then
        if player:getMark(fuyu.name) == "lose" then
          player:drawCards(2, fuyu.name)
        end
        if not player.dead then
          room:setPlayerMark(player, fuyu.name, "lose")
        end
      end
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    else
      if not player.dead then
        if player:getMark(fuyu.name) == "win" then
          player:drawCards(2, fuyu.name)
        end
        if not player.dead then
          room:setPlayerMark(player, fuyu.name, "win")
        end
      end
      data.nullified = true
    end
  end,
})

return fuyu
