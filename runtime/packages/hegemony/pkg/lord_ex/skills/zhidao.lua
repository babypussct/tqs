
local zhidao = fk.CreateSkill {
  name = "ld__zhidao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__zhidao"] = "雉盗",
  [":ld__zhidao"] = "锁定技，出牌阶段开始时，你选择一名其他角色，视为对所有其以外的其他角色使用一张【调虎离山】；"..
  "你于本阶段首次对其造成伤害后，获得其区域内的一张牌。",

  ["#ld__zhidao-choose"] = "雉盗：选择一名其他角色，视为对除其以外的角色使用【调虎离山】",

  ["$ld__zhidao1"] = "一朝得势，自当尽诸其力！",
  ["$ld__zhidao2"] = "本王要的，没有得不到的！",
}

zhidao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhidao.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ld__zhidao-choose",
      skill_name = zhidao.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, "ld__zhidao-phase", to)
    local targets = room:getOtherPlayers(player)
    table.removeOne(targets, to)
    if #targets > 0 then
      room:useVirtualCard("lure_tiger", nil, player, targets, zhidao.name)
    end
  end,
})

zhidao:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhidao.name) and
      player:getMark("ld__zhidao-phase") == data.to and
      not data.to:isAllNude() then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player and e.data.to == data.to
      end, Player.HistoryPhase)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "hej",
      skill_name = zhidao.name,
    })
    room:obtainCard(player, card, false, fk.ReasonPrey)
  end,
})

return zhidao
