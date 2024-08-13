behaviour("dvHMDC")

function dvHMDC:Start()
    self.vehicle = self.gameObject.GetComponent(Vehicle)
    self.targetObject = self.targets.targetObject
    self.activationMinAngle = 50 -- Minimum angle threshold for activation
    self.activationMaxAngle = 85 -- Maximum angle threshold for activation

    if self.vehicle == nil then
        print("Vehicle component not found!")
    end
end

function dvHMDC:FixedUpdate()
    if self.vehicle.hasDriver and self.vehicle.driver == Player.actor then
        -- Get facing direction of the player
        local playerFacingDirection = Player.actor.facingDirection
        local vehicleFacingDirection = self.vehicle.transform.forward
        local angleDifference = Vector3.Angle(vehicleFacingDirection, playerFacingDirection)

        -- Check activation within the specified angle range
        if angleDifference >= self.activationMinAngle and angleDifference <= self.activationMaxAngle then
            self.targetObject:SetActive(true)
            print("Object activated at angle: " .. angleDifference)
        else
            self.targetObject:SetActive(false)
            print("Object deactivated at angle: " .. angleDifference)
        end
    end
end


