local shandao = fk.CreateSkill{
  name = "ty__shandao",
}

Fk:loadTranslationTable{
  ["ty__shandao"] = "善刀",
  [":ty__shandao"] = "出牌阶段限一次，你可以将任意名角色的区域内各一张牌置于牌堆顶，视为对这些角色使用一张【五谷丰登】，"..
  "然后视为对除这些角色外的其他角色使用一张【万箭齐发】。",

  ["#ty__shandao"] = "善刀：将任意名角色区域内各一张牌置于牌堆顶，视为对其使用【五谷丰登】，然后视为对其余角色使用【万箭齐发】",

  ["$ty__shandao1"] = "青锋者，刃藏于匣，不为刚强所折。",
  ["$ty__shandao2"] = "善刀之人有异勇，其视天下为俎上之脍。",
}

shandao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__shandao",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shandao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return not to_select:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    local tos = {}
    for _, target in ipairs(targets) do
      table.insert(tos, target)
      if not (target.dead or target:isAllNude()) then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "hej",
          skill_name = shandao.name,
        })
        room:moveCards({
          ids = {card},
          from = target,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = shandao.name,
        })
        if player.dead then return end
      end
    end
    tos = table.filter(tos, function (p)
      return not p.dead
    end)
    room:useVirtualCard("amazing_grace", nil, player, tos, shandao.name)
    if player.dead then return end
    local others = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(targets, p)
    end)
    if #others > 0 then
      room:useVirtualCard("archery_attack", nil, player, others, shandao.name)
    end
  end,
})

return shandao
