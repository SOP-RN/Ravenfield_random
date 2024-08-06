behaviour("CustomGLoc")

function CustomGLoc:Start()
    self.animator = self.gameObject.GetComponent(Animator)
    self.gValue = 0
    self.previousVelocity = Vector3.zero
    self.gForces = {0, 0, 0, 0, 0}
    self.gForceCounter = 1
    self.gLocIntensity = self.script.mutator.GetConfigurationFloat("GlocMagnitude")
    self.decayRate = self.script.mutator.GetConfigurationFloat("GlocDecay")
    self.shakeThreshold = self.script.mutator.GetConfigurationFloat("ShakeGThreshold")
    self.baseShakeIntensity = self.script.mutator.GetConfigurationFloat("ShakeBase")
    self.ShakeIntensityMultiplier = self.script.mutator.GetConfigurationFloat("ShakeMultiplier")
    self.agsmSoundBank = self.targets.AGSM.GetComponent(SoundBank)
    self.postAgsmSoundBank = self.targets.PAGSM.GetComponent(SoundBank)
    self.normalBreathingSource = self.targets.Breath.GetComponent(AudioSource)
    self.agsmThreshold = self.script.mutator.GetConfigurationFloat("SFXThreshold")
    self.agsmTimer = 0
    self.postAgsmTimer = 0
    self.postAgsmCount = 0
    self.postAgsmActive = false
    self.agsmOccurred = false
    self.SfxToggle = self.script.mutator.GetConfigurationBool("SFXTOGGLE")
    self.SfxObj = self.targets.SfxOBJ

    if not self.SfxToggle then
        self.SfxObj.SetActive(false)
    end
end

function CustomGLoc:FixedUpdate()
    local activeVehicle = Player.actor.activeVehicle

    if activeVehicle == nil then
        self.animator.SetFloat("Gvalue", 0)
        self:ControlNormalBreathing(false)
        return
    end

    if not activeVehicle.isAirplane then
        return
    end

    local rb = activeVehicle.rigidbody
    local invRotation = Quaternion.Inverse(rb.rotation)
    local accel = (rb.velocity - self.previousVelocity) / Time.fixedDeltaTime
    local gForce = ((invRotation * accel).y / 9.81) + 1

    self.gForces[self.gForceCounter] = gForce

    local sum = 0

    for _, value in pairs(self.gForces) do
        sum = sum + value
    end

    self.gValue = (sum / 5) * self.gLocIntensity

    self.gForceCounter = self.gForceCounter + 1

    if self.gForceCounter > 5 then
        self.gForceCounter = 1
    end

    self.previousVelocity = rb.velocity

    self.gValue = self.gValue * self.decayRate

    if math.abs(gForce) > self.shakeThreshold then
        local shakeIntensity = self.baseShakeIntensity + (math.abs(gForce) - self.shakeThreshold) * self.ShakeIntensityMultiplier
        PlayerCamera.ApplyScreenshake(shakeIntensity, 1)
    end

    self.animator.SetFloat("Gvalue", self.gValue)
    print(self.gValue)
    self.agsmTimer = self.agsmTimer + Time.fixedDeltaTime

    if self.gValue > self.agsmThreshold and self.agsmTimer >= 3 then
        self.agsmSoundBank:PlayRandom()
        self.agsmTimer = 0
        self.agsmOccurred = true
        self.postAgsmActive = false
        self.postAgsmCount = 0
        self:ControlNormalBreathing(false)
    end

    if self.agsmOccurred and self.gValue <= self.agsmThreshold and not self.postAgsmActive then
        self.postAgsmActive = true
        self.postAgsmTimer = 0
    end

    if self.postAgsmActive then
        self.postAgsmTimer = self.postAgsmTimer + Time.fixedDeltaTime

        if self.postAgsmTimer >= 1.8 and self.postAgsmCount < 4 then
            self.postAgsmSoundBank:PlayRandom()
            self.postAgsmTimer = 0
            self.postAgsmCount = self.postAgsmCount + 1
        end

        if self.postAgsmCount >= 4 then
            self.postAgsmActive = false
            self.agsmOccurred = false
            self:ControlNormalBreathing(true)
        end
    elseif not self.agsmOccurred and not self.postAgsmActive then
        self:ControlNormalBreathing(true)
    end
end

function CustomGLoc:ControlNormalBreathing(play)
    if play then
        self.normalBreathingSource.volume = 1.0
        self.normalBreathingSource.priority = 128
        if not self.normalBreathingSource.isPlaying then
            self.normalBreathingSource:Play()
        end
    else
        self.normalBreathingSource:Stop()
    end
end
