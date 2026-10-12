local xianglv = fk.CreateSkill {
  name = "xianglv",
  tags = { Skill.Compulsory },
  derived_piles = "xianglv",
}

Fk:loadTranslationTable{
  ["xianglv"] = "相旅",
  [":xianglv"] = "锁定技，游戏开始时，你将牌堆中每个牌名的各一张基本牌置于你的武将牌上；" ..
  "当你登场一名“<a href='#tuoquan_fuchen'>季汉辅臣</a>”后，你随机获得一张“相旅”牌。",

  ["$xianglv1"] = "相父北伐时，植柏于此，今枝繁叶茂，恰可蔽日。",
  ["$xianglv2"] = "相父羽扇纶巾在侧，朕如磐石高枕无忧。",
}

xianglv:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianglv.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local basics = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        basics[card.trueName] = basics[card.trueName] or {}
        table.insert(basics[card.trueName], id)
      end
    end

    if next(basics) == nil then
      return false
    end

    local toObtain = {}
    for name, _ in pairs(basics) do
      table.insert(toObtain, room:tableRandomPick(basics[name]))
    end

    if #toObtain == 0 then
      return false
    end

    player:addToPile("xianglv", toObtain, true, xianglv.name, player)
  end,
})

return xianglv
