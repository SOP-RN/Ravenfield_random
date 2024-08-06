behaviour("dvGsim")

function dvGsim:Start()
    self.vehicle = self.gameObject.GetComponent(Vehicle)
    self.gText = self.targets.gText.GetComponent(Text)
    self.gValue = 0
    self.previousVelocity = Vector3.zero
    self.updateInterval = 0.1
    self.timeSinceLastUpdate = 0
end

function dvGsim:FixedUpdate()
    if self.vehicle.hasDriver and self.vehicle.driver == Player.actor then
        local rb = self.vehicle.gameObject.GetComponent(Rigidbody)
        local currentVelocity = rb.velocity
        local acceleration = (currentVelocity - self.previousVelocity) / Time.fixedDeltaTime

        -- Use vehicle's downward direction
        local gravityDirection = Vector3(0, 1, 0)
        local totalAcceleration = acceleration + gravityDirection * 9.8
        local gForce = totalAcceleration.magnitude / 9.8
        local sign = Vector3.Dot(totalAcceleration, self.vehicle.transform.up) >= 0 and 1 or -1
        gForce = gForce * sign
        self.gValue = gForce

        -- Update text every 0.1 second
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + Time.fixedDeltaTime
        if self.timeSinceLastUpdate >= self.updateInterval then
            self.timeSinceLastUpdate = 0
            local gForceText = string.format("%.1f", self.gValue)
            if self.gText ~= nil then
                self.gText.text = gForceText
            end
        end

        -- Store current velocity for next frame
        self.previousVelocity = currentVelocity
    end
end
