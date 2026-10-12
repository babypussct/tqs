local hegNullificationSkill = fk.CreateSkill{
  name = "heg__nullification_skill",
}

local H = require "packages.hegemony.util"

hegNullificationSkill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
  on_use = function(self, room, use)
    if use.responseToEvent and use.responseToEvent.to and #use.responseToEvent.tos > 1 then
      local from = use.from
      local to = use.responseToEvent.to
      if to.kingdom ~= "unknown" then
        local choices = {"hegN-single::" .. to.id, "hegN-all:::" .. to.kingdom}
        local choice = room:askToChoice(from, {choices = choices, skill_name = "heg__nullification", prompt = "#hegN-ask"})
        if choice:startsWith("hegN-all") then
          room:sendLog{
            type = "#HegNullificationAll",
            from = from.id,
            arg = to.kingdom,
            card = Card:getIdList(use.card),
            toast = true,
          }
          use.extra_data = use.extra_data or {}
          use.extra_data.hegN_all = true
        else
          room:sendLog{
            type = "#HegNullificationSingle",
            from = from.id,
            to = {to.id},
            card = Card:getIdList(use.card),
            toast = true,
          }
        end
      end
    end
  end,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
      if (effect.extra_data or {}).hegN_all then
        local to = effect.responseToEvent.to
        effect.responseToEvent.use.disresponsiveList = effect.responseToEvent.use.disresponsiveList or {}
        effect.responseToEvent.use.nullifiedTargets = effect.responseToEvent.use.nullifiedTargets or {}
        for _, p in ipairs(room.alive_players) do
          if H.compareKingdomWith(p, to) then
            table.insertIfNeed(effect.responseToEvent.use.nullifiedTargets, p)
            table.insertIfNeed(effect.responseToEvent.use.disresponsiveList, p)
          end
        end
      end
    end
  end
})

hegNullificationSkill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 4,
  use_value = 7.8,
})

Fk:loadTranslationTable{
  ["heg__nullification"] = "无懈可击·国",
  ["heg__nullification_skill"] = "无懈可击·国",
  [":heg__nullification"] = "锦囊牌<br/><b>时机</b>：当锦囊牌对目标生效前<br/><b>目标</b>：此牌<br/><b>效果</b>：抵消此牌。你令对对应的角色为与其势力相同的角色的目标结算的此牌不是【无懈可击】的合法目标，当此牌对对应的角色为这些角色中的一名的目标生效前，抵消此牌。",
  ["#hegN-ask"] = "无懈可击·国：请选择",
  ["hegN-single"] = "对%dest使用",
  ["hegN-all"] = "对%arg势力使用",
  ["#HegNullificationSingle"] = "%from 选择此 %card 对 %to 生效",
  ["#HegNullificationAll"] = "%from 选择此 %card 对 %arg 势力生效",
}

return hegNullificationSkill
