local osDaigui = fk.CreateSkill {
  name = "os__daigui"
}

Fk:loadTranslationTable{
  ["os__daigui"] = "待归",
  [":os__daigui"] = "出牌阶段结束时，若你手牌的颜色均相同，你可选择至多X名角色，然后亮出牌堆底等同这些角色数的牌，" ..
  "这些角色依次获得其中的一张（X为你的手牌数）。",

  ["#os__daigui-choose"] = "待归：选择至多 %arg 名角色，亮出牌堆底等量张牌，各获得一张",
  ["#os__daigui-card"] = "待归：选择一张牌获得",

  ["$os__daigui1"] = "勤耕陇亩地，并修德与身。",
  ["$os__daigui2"] = "田垄不可废，耕读不可怠。",
}

osDaigui:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if
      target == player and
      player:hasSkill(osDaigui.name) and
      player.phase == Player.Play and
      not player:isKongcheng()
    then
      local card = Fk:getCardById(player:getCardIds("h")[1])
      return table.every(player:getCardIds("h"), function(cid)
        return card:compareColorWith(Fk:getCardById(cid))
      end)
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = player:getHandcardNum(),
        prompt = "#os__daigui-choose:::" .. player:getHandcardNum(),
        skill_name = osDaigui.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osDaigui.name
    local room = player.room
    local tos = event:getCostData(self)
    room:sortByAction(tos)
    local cards = room:getNCards(#tos, "bottom")
    room:turnOverCardsFromDrawPile(player, cards, skillName)
    for _, p in ipairs(tos) do
      cards = table.filter(cards, function(c) return room:getCardArea(c) == Card.Processing end)
      if p:isAlive() and #cards > 0 then
        local c = room:askToChooseCards(
          p,
          {
            target = p,
            min = 1,
            max = 1,
            flag = { card_data = {{ skillName, cards }} },
            skill_name = skillName,
            prompt = "#os__daigui-card",
          }
        )
        table.removeOne(cards, c)
        room:obtainCard(p, c, true, fk.ReasonPrey, player, skillName)
      end
    end
    room:cleanProcessingArea(cards, skillName)
  end,
})

return osDaigui
