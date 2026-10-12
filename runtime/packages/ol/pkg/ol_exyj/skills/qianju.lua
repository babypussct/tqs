
local qianju = fk.CreateSkill {
  name = "ol_ex__qianju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__qianju"] = "千驹",
  [":ol_ex__qianju"] = "锁定技，你每损失1点体力，你计算与其他角色的距离便-1。"..
  "出牌阶段开始时，若全场其他角色均在你的攻击范围内，你本回合使用【杀】的次数+1，并获得一张攻击范围X的武器牌（X为你已损失体力值且每个范围限一次）。",
}

qianju:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qianju.name) and player.phase == Player.Play and
      table.every(player.room:getOtherPlayers(player, false), function (p)
        return player:inMyAttackRange(p)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 1)
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)  ---@cast card Weapon
      if card.sub_type == Card.SubtypeWeapon and card:getAttackRange() == player:getLostHp() and
        not table.contains(player:getTableMark(qianju.name), card:getAttackRange()) then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      local card = room:tableRandomPick(cards)
      room:addTableMark(player, qianju.name, Fk:getCardById(card):getAttackRange())
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, qianju.name, nil, false, player)
    end
  end,
})

qianju:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(qianju.name) then
      return -from:getLostHp()
    end
  end,
})

return qianju
