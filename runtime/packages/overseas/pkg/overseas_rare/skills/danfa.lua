local danfa = fk.CreateSkill {
  name = "os__danfa",
  derived_piles = { "os__cinnabar" },
}

Fk:loadTranslationTable{
  ["os__danfa"] = "丹法",
  [":os__danfa"] = "当你使用或打出牌结算结束后，若你没有此花色的“丹”，你可以将此牌置于武将牌上，称为“丹”。",

  ["os__cinnabar"] = "丹",
  ["@[suits]os__cinnabar"] = "丹", -- 宝宝。不改造私人牌堆显示的方法

  ["$os__danfa1"] = "取五灵三使之药，炼九光七曜之丹。",
  ["$os__danfa2"] = "云液踊跃成雪霜，流珠之英能延年。",
}

---@type TrigSkelSpec<UseCardFunc|RespondCardFunc>
local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(danfa.name) and
      data.card.suit ~= Card.NoSuit and
      not table.find(player:getPile("os__cinnabar"), function(id)
        return Fk:getCardById(id):compareSuitWith(data.card)
      end) and
      (player.room:getCardArea(data.card) == Card.Processing or
      (table.every(Card:getIdList(data.card), function(id)
        return player.room:getCardOwner(id) == player
      end)))
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("os__cinnabar", data.card, true, danfa.name, player)
    if player:isAlive() then
      local suits = table.map(player:getPile("os__cinnabar"), function(id)
        return Fk:getCardById(id).suit
      end)
      player.room:setPlayerMark(player, "@[suits]os__cinnabar", suits) -- 宝宝。不改造私人牌堆显示的方法
    end
  end,
}

danfa:addEffect(fk.CardUseFinished, spec)
danfa:addEffect(fk.CardRespondFinished, spec)

danfa:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[suits]os__cinnabar", 0)
end)

return danfa
