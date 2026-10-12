local zhuangrong = fk.CreateSkill{
  name = "ol__zhuangrong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__zhuangrong"] = "妆戎",
  [":ol__zhuangrong"] = "锁定技，回合开始时，将以下随机一件装备置入你的空置装备栏："..
    "【束发紫金冠】【玲珑狮蛮带】【红锦百花袍】【无双方天戟】（每件限一次，离开装备区后销毁）。"..
    "每回合结束时，若你发动这些装备的效果至少两次，你增加1点体力上限，回复1点体力（每局游戏限一次）。",

  ["@$ol__zhuangrong"] = "妆戎",

  ["$ol__zhuangrong1"] = "乘赤兔，舞画戟，温侯之志岂绝于此？",
  ["$ol__zhuangrong2"] = "勇士之血，才是最好的红妆。",
}

local zhuangrong_equips = {
  {"golden_coronet", Card.Diamond, 12},
  {"lion_belt", Card.Spade, 2},
  {"red_robe", Card.Club, 1},
  {"matchless_halberd", Card.Diamond, 12}
}

zhuangrong:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@$ol__zhuangrong",
    player.room:prepareDeriveCards(zhuangrong_equips, "ol__zhuangrong_derivecards"))
end)

zhuangrong:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@$ol__zhuangrong", 0)
end)

zhuangrong:addEffect(fk.TurnStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhuangrong.name) then
      local room = player.room
      return not not table.find(player:getTableMark("@$ol__zhuangrong"), function(id)
        if room:getCardArea(id) == Card.Void then
          local card = Fk:getCardById(id)
          return player:hasEmptyEquipSlot(card.sub_type)
        end
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$ol__zhuangrong")
    local cards = table.filter(mark, function(id)
      if room:getCardArea(id) == Card.Void then
        local card = Fk:getCardById(id)
        return player:hasEmptyEquipSlot(card.sub_type)
      end
    end)
    if #cards == 0 then return end
    local id = room:tableRandomPick(cards)
    table.removeOne(mark, id)
    room:setPlayerMark(player, "@$ol__zhuangrong", mark)
    room:moveCardTo(id, Card.PlayerEquip, player, fk.ReasonPut, zhuangrong.name, nil, true, player, MarkEnum.DestructOutMyEquip)
  end,
})

zhuangrong:addEffect(fk.TurnEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhuangrong.name) and player:usedEffectTimes(self.name, Player.HistoryGame) == 0 then
      local x = 0
      for _, name in ipairs({"#golden_coronet_skill", "#lion_belt_skill", "#red_robe_skill", "#matchless_halberd_skill"}) do
        x = x + player:usedSkillTimes(name, Player.HistoryGame)
        if x > 1 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhuangrong.name,
      }
    end
  end,
})

return zhuangrong
