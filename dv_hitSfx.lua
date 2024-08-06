behaviour("SoundOnHitController")

function SoundOnHitController:Awake()
    self.soundBank = self.targets.SoundBank.GetComponent(SoundBank)
    Player.actor.onTakeDamage.AddListener(self, "onTakeDamage")
end

function SoundOnHitController:onTakeDamage(actor, source, info)
    local activeVehicle = Player.actor.activeVehicle

    if activeVehicle ~= nil then
        self:PlayHitSound()
    end
end

function SoundOnHitController:PlayHitSound()
    self.soundBank:PlayRandom()
end
