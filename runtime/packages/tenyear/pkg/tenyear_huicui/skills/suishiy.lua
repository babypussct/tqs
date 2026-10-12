local suishiy = fk.CreateSkill {
  name = "suishiy",
}

Fk:loadTranslationTable{
  ["suishiy"] = "邃识",
  [":suishiy"] = "一名角色的结束阶段，若其手牌数不小于体力值，你可以声明一种伤害牌牌名，令其可以将一张牌当此牌使用，"..
  "若此牌造成伤害，受到伤害的角色不能使用与造成伤害的牌颜色相同的牌直到其回合结束。",

  ["#suishiy-invoke"] = "邃识：选择一种伤害牌，%dest 可以将一张牌当此牌使用",
  ["#suishiy-use"] = "邃识：你可以将一张牌当【%arg】使用",
  ["@suishiy"] = "邃识",

  ["$suishiy1"] = "孙伯符，汝当真要作忘恩负义之徒吗？",
  ["$suishiy2"] = "养虎不羁，饲者必成虎口之张。",
}

local U = require "packages.utility.utility"

suishiy:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return not target.dead and target.phase == Player.Finish and player:hasSkill(suishiy.name) and
      target:getHandcardNum() >= target.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cardMap = room:getBanner(suishiy.name)
    local names = {}
    if cardMap == nil then
      cardMap = {}
      local temp = {}
      local name
      for _, card in ipairs(Fk.cards) do
        if not table.contains(room.disabled_packs, card.package.name) and not card.is_derived then
          if card.is_damage_card then
            name = card.trueName
            if card.type == Card.TypeBasic then
              table.insertIfNeed(names, name)
              cardMap[name] = cardMap[name] or {}
              table.insertIfNeed(cardMap[name], card.name)
            else
              table.insertIfNeed(temp, name)
              cardMap[name] = cardMap[name] or {}
              table.insertIfNeed(cardMap[name], card.name)
            end
          end
        end
      end
      names = table.connect(names, temp)
      cardMap["AllCardNames"] = names
      room:setBanner(suishiy.name, cardMap)
    else
      names = cardMap["AllCardNames"]
    end
    local choices = U.askForChooseCardNames(room, player, names, 1, 1, suishiy.name,
      "#suishiy-invoke::"..target.id, nil, true)
    if #choices == 1 then
      event:setCostData(self, { tos = { target }, choice = choices[1], choices = cardMap[choices[1]] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local choice = event:getCostData(self).choice
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = choice,
      toast = true,
    }
    room:askToUseVirtualCard(target, {
      name = event:getCostData(self).choices,
      skill_name = suishiy.name,
      prompt = "#suishiy-use:::"..choice,
      cancelable = true,
      card_filter = {
        n = 1,
      },
    })
  end,
})

suishiy:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and data.card and table.contains(data.card.skillNames, suishiy.name) and
      data.card.color ~= Card.NoColor and data.damageDealt and data.damageDealt[player]
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@suishiy", data.card:getColorString())
  end,
})

suishiy:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@suishiy", 0)
  end,
})

suishiy:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    local colors = player:getTableMark("@suishiy")
    if #colors > 0 then
      return not card:matchVSPattern(".|.|^(" .. table.concat(colors, ",") .. ")")
    end
  end,
})

return suishiy
