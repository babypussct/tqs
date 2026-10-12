local zhefu = fk.CreateSkill{
  name = "heg__zhefu",
}

Fk:loadTranslationTable{
  ["heg__zhefu"] = "哲妇",
  [":heg__zhefu"] = "当你于回合外使用或打出基本牌后，你可以观看一名同势力角色数不小于你的角色的手牌，然后你可以弃置其中一张基本牌。",

  ["#heg__zhefu-choose"] = "哲妇：你可以观看其中一名角色的手牌并弃置其中一张基本牌",
  ["#heg__zhefu-discard"] = "哲妇：你可以弃置其中一张基本牌",

  ["$heg__zhefu1"] = "非我善妒，实乃汝之过也！",
  ["$heg__zhefu2"] = "履行不端者，当有此罚。",
}

local H = require "packages.hegemony.util"

Fk:addPoxiMethod{
  name = "heg__zhefu",
  prompt = "#heg__zhefu-discard",
  card_filter = function(to_select, selected, data)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  feasible = Util.TrueFunc,
}

local zhefu_spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhefu.name) and
      player.room.current ~= player and data.card.type == Card.TypeBasic and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng() and
          H.getSameKingdomPlayersNum(player.room, p) >= H.getSameKingdomPlayersNum(player.room, player)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng() and
          H.getSameKingdomPlayersNum(room, p) >= H.getSameKingdomPlayersNum(room, player)
      end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhefu.name,
      prompt = "#heg__zhefu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local result = room:askToPoxi(player, {
      poxi_type = zhefu.name,
      data = {
        { to.general, to:getCardIds("h") },
      },
      cancelable = true,
    })
    if #result > 0 then
      room:throwCard(result, zhefu.name, to, player)
    end
  end,
}

zhefu:addEffect(fk.CardUseFinished, zhefu_spec)
zhefu:addEffect(fk.CardRespondFinished, zhefu_spec)

return zhefu
