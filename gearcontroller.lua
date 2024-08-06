behaviour("gearcontroller")
    --local instance
    function gearcontroller:Start()
        self.vehicle = self.gameObject.GetComponent(Vehicle)
        self.animator = self.targets.animator
        self.check = 0
    end

function gearcontroller:Update()
    if self.vehicle.hasDriver then
        if self.vehicle.driver == Player.actor then
            if Input.GetKeyBindButtonDown(KeyBinds.Prone) then
                if self.check == 0 then
                    self.check = 1
                else
                    self.check = 0
                end
                self.animator.SetFloat("GearStat", self.check)
            end
        end
        if self.vehicle.driver.isBot then
            if self.check == 0 and self.vehicle.altitude > 20 then
                self.check = 1
                self.animator.SetFloat("GearStat", self.check)
            end
        end
    end
end
