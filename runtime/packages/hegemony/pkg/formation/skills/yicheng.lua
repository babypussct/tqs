local yicheng = fk.CreateSkill{
  name = "yicheng",
}

Fk:loadTranslationTable{
  ["yicheng"] = "疑城",
  [":yicheng"] = "当你使用【杀】指定目标后，或与你势力相同的角色成为【杀】的目标后，你可以选择目标X张牌移出游戏直到本回合结束（X为其体力值，不足全选），若此【杀】未造成伤害，你摸一张牌。",

  ["#yicheng-invoke"] = "疑城：你可以扣置 %dest %arg张牌",
  ["heg__yicheng"] = "疑城",

  ["$yicheng1"] = "不怕死，就尽管放马过来！",
  ["$yicheng2"] = "待末将布下疑城，以退曹贼。",
}

local H = require "packages.hegemony.util"

yicheng:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yicheng.name) and H.compareKingdomWith(target, player) and data.card.trueName == "slash"
    and player:hasShownSkill(yicheng.name) and not target:isNude()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      skill_name = yicheng.name,
      target = target,
      flag = "he",
      min = target.hp,
      max = target.hp,
      prompt = "#ld__yicheng-invoke::"..target.id..":"..target.hp,
    })
    target:addToPile("heg__yicheng", cards, false, yicheng.name, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.yichengUser = data.extra_data.yichengUser or {}
    data.extra_data.yichengUser = player.id
  end,
})

yicheng:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yicheng.name) and data.card.trueName == "slash" and target == player
    and not data.to:isNude()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      skill_name = yicheng.name,
      target = data.to,
      flag = "he",
      min = data.to.hp,
      max = data.to.hp,
      prompt = "#yicheng-invoke::"..data.to.id..":"..data.to.hp,
    })
    data.to:addToPile("heg__yicheng", cards, false, yicheng.name, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.yichengUser = data.extra_data.yichengUser or {}
    data.extra_data.yichengUser = player.id
  end,
})

yicheng:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return not data.damageDealt and (data.extra_data or {}).yichengUser == player.id
  end,
  on_use = function (self, event, target, player, data)
    if not player.dead then
      player:drawCards(1, yicheng.name)
    end
  end,
})

yicheng:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("heg__yicheng") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("heg__yicheng"), Player.Hand, player, fk.ReasonPrey, yicheng.name)
  end,
})

return yicheng
