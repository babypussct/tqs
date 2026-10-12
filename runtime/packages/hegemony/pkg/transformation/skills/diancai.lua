
local diancai = fk.CreateSkill{
  name = "diancai",
}

Fk:loadTranslationTable{
  ["diancai"] = "典财",
  [":diancai"] = "其他角色的出牌阶段结束时，若你于此阶段失去过不少于X张牌（X为你的体力值），则你可将手牌摸至你体力上限，然后你可变更副将。",

  ["#diancai-ask"] = "典财：你可摸 %arg 张牌，然后你可变更副将",

  ["$diancai1"] = "军资之用，不可擅作主张！",
  ["$diancai2"] = "善用资财，乃为政上法！",
}

local H = require "packages.hegemony.util"
diancai:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(diancai.name) or target.phase ~= Player.Play or target == player then return false end
    local num = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move and move.from and move.from == player and ((move.to and move.to ~= player) or not table.contains({Card.PlayerHand, Card.PlayerEquip}, move.toArea)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num = num + 1
            end
          end
        end
      end
      return false
    end, Player.HistoryPhase)
    return num >= player.hp
  end,
  on_use = function(self, event, target, player, data)
    local num = player.maxHp - player:getHandcardNum()
    local room = player.room
    if num > 0 then
      player:drawCards(num, diancai.name)
    end
    if player:isAlive()
      and room:askToChoice(player, {
        choices = {"transformDeputy", "Cancel"},
        skill_name = diancai.name,
      }) ~= "Cancel" then
        H.transformGeneral(room, player)
    end
  end,
})

return diancai
