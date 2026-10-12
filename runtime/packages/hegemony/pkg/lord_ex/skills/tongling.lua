local tongling = fk.CreateSkill {
  name = "ld__tongling",
}

Fk:loadTranslationTable {
  ["ld__tongling"] = "通令",
  [":ld__tongling"] = "每阶段限一次，当你于出牌阶段内对其它势力角色造成伤害后，你可令一名与你势力相同的角色对其使用一张牌，然后若此牌：造成伤害，你与其各摸两张牌；未造成伤害，其获得你对其造成伤害的牌。",

  ["#ld__tongling-choose"] = "通令：选择一名与你势力相同的角色，其可以对%dest使用一张牌",
  ["#ld__tongling_card-use"] = "通令：你可对 %dest 使用一张牌，若此牌造成伤害，你与 %src 各摸两张牌，若此牌未造成伤害，受伤角色获得%arg",
  ["#ld__tongling_nocard-use"] = "通令：你可对 %dest 使用一张牌，若此牌造成伤害，你与 %src 各摸两张牌",

  ["$ld__tongling1"] = "孝直溢美之言，特以此小利报之，还望笑纳。",
  ["$ld__tongling2"] = "孟起，莫非甘心为他人座下之客。",
}

local H = require "packages.hegemony.util"

tongling:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(tongling.name) and
        player:usedSkillTimes(tongling.name, Player.HistoryPhase) == 0 and not data.to.dead
        and not H.compareKingdomWith(player, data.to) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    if #targets > 0 then
      local victim = data.to.id
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ld__tongling-choose::" .. victim,
        skill_name = tongling.name,
        cancelable = true,
      })
      if #to > 0 then
        local user = to[1]
        local cardNames = {}
        --local selfCards = { "peach", "analeptic", "ex_nihilo", "lightning" }   -- FIXME: how to tell ex_niholo from AOE and AG?
        for _, name in ipairs(Fk:getAllCardNames("btd", false, true)) do
              local card = Fk:cloneCard(name)
              local min_target = card.skill:getMinTargetNum(user)
              if min_target > 0 then
                table.insertIfNeed(cardNames, card.trueName)
              else
                if card.multiple_targets then
                  if card.skill:modTargetFilter(user, data.to, {}, card) then
                    table.insertIfNeed(cardNames, card.trueName)
                  end
                else
                --FIXME:不需要选目标的单目标牌，目前没有能指别人的
              end
            end
          end
        local prompt = data.card and
        "#ld__tongling_card-use:" .. player.id .. ":" .. victim .. ":" .. data.card:toLogString() or
        "#ld__tongling_nocard-use:" .. player.id .. ":" .. data.to.id
        local use = room:askToUseCard(user, {
          card_name = "",
          pattern = table.concat(cardNames, ","),
          prompt = prompt,
          skill_name = tongling.name,
          extra_data = {
            must_targets = { victim },
            bypass_times = true,
            bypass_distances = true,
          },
          cancelable = true,
        })
        if use then
          use.extra_data = use.extra_data or {}
          use.extra_data.ld__tonglingUser = player.id
          if data.card then
            use.extra_data.ld__tonglingCard = data.card ---@type Card
          end
          use.extra_data.ld__tonglingTo = victim
          use.extra_data.ld__tonglingFrom = to[1]
          use.extraUse = true
          room:useCard(use)
        end
      end
    end
  end,
})

tongling:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (data.extra_data or {}).ld__tonglingUser == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageDealt then
      local other = data.extra_data.ld__tonglingFrom
      if other ~= player then
        player:drawCards(2, tongling.name)
      end
      other:drawCards(2, tongling.name)
    else
      local card = data.extra_data.ld__tonglingCard
      if not card then return end
      if room:getCardArea(card) == Card.Processing then
        room:obtainCard(data.extra_data.ld__tonglingTo, card, true, fk.ReasonJustMove)
      end
    end
  end,

})

return tongling
