
local xingzhao = fk.CreateSkill {
  name = "nos_heg__xingzhao",
  tags = { Skill.Compulsory },
  related_skills = { "ld__xunxun" },
}

Fk:loadTranslationTable {
  ["nos_heg__xingzhao"] = "兴棹",
  [":nos_heg__xingzhao"] = "锁定技，你根据场上有受伤角色的势力数获得以下效果：1个或以上，你拥有〖恂恂〗；"..
  "2个或以上，当你受到伤害后，你与伤害来源中手牌数唯一最少的角色摸一张牌；"..
  "3个或以上，你于回合内手牌上限+4；4个或以上，你失去装备区内的牌时，摸一张牌。",

  ["$nos_heg__xingzhao1"] = "精挑细选，方能成百年之计。",
  ["$nos_heg__xingzhao2"] = "拿些上好的木料来。",
}

local H = require "packages.hegemony.util"

--获取场上有受伤角色的势力数
---@param room AbstractRoom
---@return integer
local kingdoms_wounded = function(room)
  local kingdoms = {}
  for _, p in ipairs(table.filter(room.alive_players, function(p)
    return p:isWounded() and p.kingdom ~= "unknown"
  end)) do
    table.insertIfNeed(kingdoms, H.getKingdom(p))
  end
  return math.max(#kingdoms, 0)
end

--兴棹1 获得"恂恂"
local spec = {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xingzhao.name) and player:hasShownSkill(xingzhao.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:hasShownSkill(xingzhao.name) and kingdoms_wounded(room) > 0 then
      room:handleAddLoseSkills(player, "ld__xunxun", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-ld__xunxun", nil, false, true)
    end
  end,
}

xingzhao:addEffect(fk.GeneralRevealed, spec)
xingzhao:addEffect(fk.GeneralHidden, spec)
xingzhao:addEffect(fk.Death, spec)
xingzhao:addEffect(fk.HpChanged, spec)
xingzhao:addEffect(fk.MaxHpChanged, spec)
xingzhao:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingzhao.name) and player:hasShownSkill(xingzhao.name)
  end,
  on_refresh = spec.on_refresh,
})

--兴棹2 受到伤害摸牌
xingzhao:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and  player:hasSkill(xingzhao.name) and
      kingdoms_wounded(player.room) > 1 and
      data.from and (data.from == player or data.from:getHandcardNum() ~= player:getHandcardNum())
  end,
  on_use = function(self, event, target, player, data)
    if player:getHandcardNum() > data.from:getHandcardNum() then
      data.from:drawCards(1, xingzhao.name)
    else
      player:drawCards(1, xingzhao.name)
    end
  end,
})

--兴棹3 手牌上限+4
xingzhao:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(xingzhao.name) and player:hasShownSkill(xingzhao.name) and
      kingdoms_wounded(Fk:currentRoom()) > 2 and Fk:currentRoom():getCurrent() == player then
      return 4
    end
  end
})

--兴棹4 失去装备摸一张
xingzhao:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xingzhao.name) and kingdoms_wounded(player.room) > 3 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xingzhao.name)
  end
})

return xingzhao
