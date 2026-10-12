local jiaozi = fk.CreateSkill{
  name = "jiaozi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaozi"] = "骄恣",
  [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌为全场唯一最多，则此伤害+1。",

  ["$jiaozi1"] = "数战之功，吾应得此赏！",
  ["$jiaozi2"] = "无我出力，怎会连胜？",
}

local jiaozi_spec = { ---@type TrigSkelSpec<fun(self: TriggerSkill, event: DamageEvent, target: ServerPlayer, player: ServerPlayer, data: DamageData):any>
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jiaozi.name) and
      table.every(player.room:getOtherPlayers(player, false), function(p)
        return player:getHandcardNum() > p:getHandcardNum()
      end) then
      event:setCostData(self, { tos = { data.to }, anim_type = (event == fk.DamageInflicted and "negative") })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
}

jiaozi:addEffect(fk.DamageCaused, jiaozi_spec)
jiaozi:addEffect(fk.DamageInflicted, jiaozi_spec)

return jiaozi
