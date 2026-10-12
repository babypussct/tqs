local danlie = fk.CreateSkill {
  name = "os__danlie",
}

Fk:loadTranslationTable{
  ["os__danlie"] = "胆烈",
  [":os__danlie"] = "出牌阶段限一次，你可以与至多三名角色<a href='#JointPindianDesc'>共同拼点</a>，若你：赢，你对没赢的角色造成1点伤害；" ..
  "没赢，你失去1点体力。你的拼点牌点数+X（X为你已损失的体力值）。",

  ["#os__danlie"] = "胆烈：与至多3名角色共同拼点，若你赢则对他们造成伤害，没赢则你失去体力",

  ["$os__danlie1"] = "师者如父，辱师之仇亦如辱父！",
  ["$os__danlie2"] = "壮士自怀豪烈胆，初生幼虎敢搏龙！",
}

local U = require "packages.utility.utility"

danlie:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__danlie",
  times = function (self, player)
    return 1 - player:usedEffectTimes(self.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  min_target_num = 1,
  max_target_num = 3,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and player:canPindian(to_select) and #selected < 3
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = danlie.name
    local player = effect.from
    local targets = effect.tos
    -- local pd = player:pindian(table.map(targets, Util.Id2PlayerMapper), self.name)
    local pd = U.jointPindian(player, targets, skillName)
    if pd.winner == player then
      for _, p in ipairs(targets) do
        if p:isAlive() then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = skillName,
          }
        end
      end
    elseif player:isAlive() then
      room:loseHp(player, 1, skillName)
    end
  end,
})

danlie:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(danlie.name) and (data.from == player or table.contains(data.tos, player)) and player:isWounded()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changePindianNumber(data, player, player:getLostHp(), danlie.name)
  end,
})

return danlie
